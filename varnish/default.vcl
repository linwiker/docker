vcl 4.0;
import directors;

backend backendsrv {
    .host = "${VARNISH_BACKEND_IP}";
    .port = "${VARNISH_BACKEND_PORT}";
    .first_byte_timeout     = 300s;   # How long to wait before we receive a first byte from our backend?
    .connect_timeout        = 5s;     # How long to wait for a backend connection?
    .between_bytes_timeout  = 2s;     # How long to wait between bytes received from our backend?
}


sub vcl_init {
    new vdir = directors.round_robin();
    vdir.add_backend(backendsrv);
}

acl purge {
    "127.0.0.1";
    "localhost";
}

sub vcl_recv {

    set req.backend_hint = vdir.backend();

    if (req.restarts == 0) {
        if (req.http.X-Forwarded-For) {
            set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", client.ip";
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }

    # Normalize the header, remove the port (in case you're testing this on various TCP ports)
    set req.http.Host = regsub(req.http.Host, ":[0-9]+", "");

    # Allow purging
    if (req.method == "PURGE") {
        if (!client.ip ~ purge) {
            return (synth(405, "This IP is not allowed to send PURGE requests."));
        }
        return (purge);
    }

    # Only deal with "normal" types
    if (req.method != "GET" &&
        req.method != "HEAD" &&
        req.method != "PUT" &&
        req.method != "POST" &&
        req.method != "TRACE" &&
        req.method != "OPTIONS" &&
        req.method != "TRACE" &&
        req.method != "OPTIONS" &&
        req.method != "PATCH" &&
        req.method != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return (pipe);
    }

    # Only cache GET or HEAD requests. This makes sure the POST requests are always passed.
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    # Some generic URL manipulation, useful for all templates that follow
    # First remove the Google Analytics added parameters, useless for our backend
    if (req.url ~ "(\?|&)(utm_source|utm_medium|utm_campaign|gclid|cx|ie|cof|siteurl)=") {
        set req.url = regsuball(req.url, "&(utm_source|utm_medium|utm_campaign|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "");
        set req.url = regsuball(req.url, "\?(utm_source|utm_medium|utm_campaign|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "?");
        set req.url = regsub(req.url, "\?&", "?");
        set req.url = regsub(req.url, "\?$", "");
    }

    # Strip hash, server doesn't need it.
    if (req.url ~ "\#") {
        set req.url = regsub(req.url, "\#.*$", "");
    }

    # Strip a trailing ? if it exists
    if (req.url ~ "\?$") {
        set req.url = regsub(req.url, "\?$", "");
    }

    # Normalize Accept-Encoding header
    # straight from the manual: https://www.varnish-cache.org/docs/3.0/tutorial/vary.html
    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2|tbz|mp3|ogg)$") {
            # No point in compressing these
            unset req.http.Accept-Encoding;
        } elsif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elsif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            # unkown algorithm
            unset req.http.Accept-Encoding;
        }
    }

    # Large static files should be piped, so they are delivered directly to the end-user without
    # waiting for Varnish to fully read the file first.
    # TODO: once the Varnish Streaming branch merges with the master branch, use streaming here to avoid locking.
    if (req.url ~ "^[^?]*\.(mp[34]|rar|tar|tgz|gz|wav|zip)(\?.*)?$") {
        unset req.http.Cookie;
        return (pipe);
    }

    # Remove all cookies for static files
    # A valid discussion could be held on this line: do you really need to cache static files that don't cause load? Only if you have memory left.
    # Sure, there's disk I/O, but chances are your OS will already have these files in their buffers (thus memory).
    # Before you blindly enable this, have a read here: http://mattiasgeniar.be/2012/11/28/stop-caching-static-files/



    if (req.url ~ "(bmp(\w(\d)+x(\d)+)?|bz2|css|doc|eot|flv|gif(!\w\d+x\d+)?|ico|jpeg(!\w\d+x\d+)?|jpg(!\w\d+x\d+)?|js|pdf|png(!\w\d+x\d+)?|rtf|swf|tif(!\w\d+x\d+)?|tiff|txt|wmf|woff|xml)(\?.*)?$") {
        unset req.http.Cookie;
        return (hash);
    }

    # Send Surrogate-Capability headers to announce ESI support to backend
    # set req.http.Surrogate-Capability = "key=ESI/1.0";

    if (req.http.Authorization) {
        # Not cacheable by default
        return (pass);
    }

    return (hash);
}

sub vcl_pipe {
    # Note that only the first request to the backend will have
    # X-Forwarded-For set.  If you use X-Forwarded-For and want to
    # have it set for all requests, make sure to have:
    # set bereq.http.connection = "close";
    # here.  It is not set by default as it might break some broken web
    # applications, like IIS with NTLM authentication.

    #set bereq.http.Connection = "Close";
    return (pipe);
}

# The data on which the hashing will take place
sub vcl_hash {
    hash_data(req.url);
    # hash cookies for requests that have them
#    if (req.http.Cookie) {
#        hash_data(req.http.Cookie);
#    }
}

sub vcl_hit {
    return (deliver);
}

sub vcl_miss {
    return (fetch);
}

# Handle the HTTP request coming from our backend
sub vcl_backend_response {
    # Pause ESI request and remove Surrogate-Control header
#    if (beresp.http.Surrogate-Control ~ "ESI/1.0") {
#        unset beresp.http.Surrogate-Control;
#        set beresp.do_esi = true;
#    }

    # Enable cache for all static files
    # The same argument as the static caches from above: monitor your cache size, if you get data nuked out of it, consider giving up the static file cache.
    # Before you blindly enable this, have a read here: http://mattiasgeniar.be/2012/11/28/stop-caching-static-files/
    if (bereq.url ~ "(bmp(\w(\d)+x(\d)+)?|bz2|css|doc|eot|flv|gif(!\w\d+x\d+)?|ico|jpeg(!\w\d+x\d+)?|jpg(!\w\d+x\d+)?|js|pdf|png(!\w\d+x\d+)?|rtf|swf|tif(!\w\d+x\d+)?|tiff|txt|wmf|woff|xml)(\?.*)?$") {
#        unset beresp.http.set-cookie;
        unset beresp.http.Vary;
    }

    # Sometimes, a 301 or 302 redirect formed via Apache's mod_rewrite can mess with the HTTP port that is being passed along.
    # This often happens with simple rewrite rules in a scenario where Varnish runs on :80 and Apache on :8080 on the same box.
    # A redirect can then often redirect the end-user to a URL on :8080, where it should be :80.
    # This may need finetuning on your setup.
    #
    # To prevent accidental replace, we only filter the 301/302 redirects for now.
    if (beresp.status == 301 || beresp.status == 302) {
        set beresp.http.Location = regsub(beresp.http.Location, ":[0-9]+", "");
    }

    # Set 2min cache if unset for static files
    if (beresp.ttl <= 0s || beresp.http.Set-Cookie || beresp.http.Vary == "*") {
        set beresp.ttl = 120s;
        set beresp.uncacheable = true;
        return (deliver);
    }
                                                            
    if (beresp.ttl > 0s) {
        /* Remove Expires from backend, it's not long enough */
        unset beresp.http.expires;

        /* Set the clients TTL on this object */
        set beresp.http.cache-control = "max-age=315360000";

        /* Set how long Varnish will keep it */
        set beresp.ttl = 10d;

        /* marker for vcl_deliver to reset Age: */
        set beresp.http.magicmarker = "1";
     }

    # Allow stale content, in case the backend goes down.
    set beresp.grace = 6h;

    return (deliver);
}

# The routine when we deliver the HTTP request to the user
# Last chance to modify headers that are sent to the client
sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.v3001-Cache = "HIT";
    } else {
        set resp.http.v3001-Cache = "MISS";
    }

    # Remove some headers: PHP version
    unset resp.http.X-Powered-By;

    # Remove some headers: Apache version & OS
    unset resp.http.Server;
    unset resp.http.X-Drupal-Cache;
    unset resp.http.X-Varnish;
    unset resp.http.Via;
    unset resp.http.Link;
    unset resp.http.Age;

    if (resp.http.magicmarker) {
        /* Remove the magic marker */
        unset resp.http.magicmarker;

        /* By definition we have a fresh object */
        set resp.http.age = "0";
    }
    return (deliver);
}

sub vcl_synth {
    if (resp.status == 720) {
        # We use this special error status 720 to force redirects with 301 (permanent) redirects
        # To use this, call the following from anywhere in vcl_recv: error 720 "http://host/new.html"
        set resp.status = 301;
        set resp.http.Location = resp.reason;
        return (deliver);
    } elseif (resp.status == 721) {
        # And we use error status 721 to force redirects with a 302 (temporary) redirect
        # To use this, call the following from anywhere in vcl_recv: error 720 "http://host/new.html"
        set resp.status = 302;
        set resp.http.Location = resp.reason;
        return (deliver);
    }

    return (deliver);
}

sub vcl_fini {
    return (ok);
}


