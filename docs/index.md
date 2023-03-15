# mod_pascal

Apache 2.4 module implementation which is capable of executing Pascal program just like scripting language.

## Requirement

- [Free Pascal compiler](https://www.freepascal.org)
- [Apache 2.4](https://httpd.apache.org/docs/2.4/)

## Setup

### Compile mod_pascal

```
$ git clone https://github.com/zamronypj/mod_pascal.git
$ cd mod_pascal && ./setup.cfg.sh && ./build.sh
```
If compilation is successful, new executable binary will be created `bin/mod_pascal.so`.

### Add Apache configuration to load module

For example in Debian,

Create `pascal.conf` file in `/etc/apache2/mods-available` directory with content as follows,

```
<IfModule pascal_module>
    # handle all files having .pas extension
    AddHandler pascal-handler .pas
</IfModule>
```

Create `pascal.load` file in `/etc/apache2/mods-available` directory with content as follows,

```
LoadModule pascal_module /path/to/mod_pascal.so
```

Do not forget to replace `/path/to/mod_pascal.so` with actual path of `mod_pascal.so`. It is important that you use `pascal_module` to identify mod_pascal module and
`pascal-handler` to identify handler.

### Enable mod_pascal

Create symlink to `pascal.conf` and `pascal.load` in `/etc/apache2/mods-enabled` directory

```
$ cd /etc/apache2/mods-enabled
$ sudo ln -s /etc/apache2/mods-available/pascal.conf
$ sudo ln -s /etc/apache2/mods-available/pascal.load
```
Alternatively, you can also use `a2enmod` command to enable mod_pascal.

```
$ sudo a2enmod pascal
```

### Restart Apache

```
$ sudo systemctl restart apache2
```

## Execute Pascal program

Create Pascal program, for example  `/var/www/html/test.pas` with content as follows,

```
begin
    writeln('Hello from Pascal');
end.
```

Open URL http://localhost/test.pas from Internet browser, you should see text `Hello from Pascal` printed in browser otherwise [things may have gone wrong](#things-can-go-wrong)

## Response header

When not set, `Content-Type` response header is assumed `text/html`.

To return response with header, add header line separated by newline

```
begin
    writeln('Content-Type: text/html');
    writeln();
    writeln('<h1>Hello from Pascal</h1>');
end.
```
or as JSON

```
begin
    writeln('Content-Type: application/json');
    writeln();
    writeln('{"message":"Hello from Pascal"}');
end.
```

Please note that, because blank newline is used to mark end of header parts of response, for safety, always add them even if you do not want to set response header. For example

```
begin
    writeln();
    writeln();
    writeln('<h1>Hello from Pascal</h1>');
end.
```

Code below will cause incorrect response

```
begin
    writeln('<h1>Hello from Pascal</h1>');
    writeln();
    writeln('test');
end.
```

To fix it, add blank newline at beginning,

```
begin
    writeln();
    writeln();
    writeln('<h1>Hello from Pascal</h1>');
    writeln();
    writeln('test');
end.
```
Or replace first `writeln()` with `write`()`,

```
begin
    write('<h1>Hello from Pascal</h1>');
    writeln();
    writeln('test');
end.
```

## CGI environment variables

From inside pascal program, [CGI environment variables](https://tools.ietf.org/html/rfc3875#section-4) can be read using `getEnvironmentVariable()`, `getEnvironmentVariableCount()` and `getEnvironmentString()` functions which is declared in `SysUtils` unit. For example,

```
uses sysutils;
var
    i:integer;
begin
    writeln('<ul>');
    for i:= 1 to getEnvironmentVariableCount do
    begin
        writeln('<li>', getEnvironmentString(i), '</li>');
    end;
    writeln('</ul>');
end.
```

## Request body

Any request body can be read from STDIN. `CONTENT_LENGTH` environment variable will contains total bytes of request body. For example, if you send following request,

```
POST /test.pas HTTP/1.1
Content-Type: application/x-www-form-urlencoded
Accept: */*
Cache-Control: no-cache
Host: localhost
Accept-Encoding: gzip, deflate, br
Content-Length: 45
Connection: keep-alive

test=hello&id=12345&user=myuser%40example.com
```
`CONTENT_LENGTH` environment variable will contains string `45` which means there is 45 bytes of data in STDIN available to read which is equal to length of string,

```
test=hello&id=12345&user=myuser%40example.com
```

If content length is greater than 0, your application needs to read it even if you do not require it.

```
uses
    sysutils;

var
    contentLen : integer;
    requestBody : string;
    ch : char;
begin
    writeln('Request body:');
    contentLen := strToInt(getEnvironmentVariable('CONTENT_LENGTH'));
    if contentLen <> 0 then
    begin
        requestBody := '';
        repeat
            read(ch);
            requestBody := requestBody + ch;
            dec(contentLen);
        until contentLen = 0;
        writeln(requestBody);
    end;
end.
```

## <a name="module-configuration"></a>More module configuration

By default, when not set, it is assumed that Free Pascal compiler path is
`/usr/local/bin/fpc`, InstantFPC path is `/usr/local/bin/instantfpc` and cache directory
in `/tmp`. You can set it to match your system as follows

```
<IfModule pascal_module>
    AddHandler pascal-handler .pas
    FpcBin /path/to/fpc
    InstantFpcBin /path/to/instantfpc
    InstantFpcCacheDir /path/to/cache/dir
</IfModule>
```

You need to make sure that cache directory is writeable by web server. After make any changes, restart Apache server.

## Compiler configuration

You can set any compiler configurations by creating `fpc.cfg` file in directory where pascal program resides. For example with content as follows,

```
# add configuration from default configuration
#INCLUDE /etc/fpc.cfg

# compile with level 3 optimization
-O3
```

## Performance consideration

This is experimental project. Using it in production setup should be avoided. Performance is not very good due
to initial compilation task that is required when any of source codes are changed.
When source codes are not changed, next execution will avoid compilation step thus give similar performance of CGI executable.

## <a name="things-can-go-wrong"></a>Things can go wrong

### Restarting Apache service fails
Make sure you set correct path to `mod_pascal.so` in `pascal.load` file.

### Pascal source code is downloaded instead of executed
If `test.pas` is downloaded then you do not register `mod_pascal` with Apache correctly. Make sure that you use correct name for handler and module which is `pascal-handler` and `pascal-module` respectively.

### Connection was reset

If browser reports "The connection to the server was reset while the page was loading." check `/var/log/apache/error.log` for error. If you get
```
An unhandled exception occurred at $00007FAB82297C74:
EProcess: Executable not found: "/usr/local/bin/instantfpc"
  $00007FAB82297C74
```
Make sure you set correct path for Free Pascal compiler and InstantFpc binaries. You can either set `FpcBin` and `InstantFpcBin` in [module configuration](#module-configuration) or create symlink to those binaries. If you set in module configuration, do not forget to restart Apache service after making changes.

### Fail to install on FreeBSD

You get error `Undefined symbol "operatingsystem_parameter_envp"`
```
# apachectl restart
Performing sanity check on apache24 configuration:
httpd: Syntax error on line 183 of /usr/local/etc/apache24/httpd.conf: Syntax error on line 9 of /usr/local/etc/apache24/modules.d/300_mod_pascal.conf: Cannot load libexec/apache24/mod_pascal.so into server: /usr/local/libexec/apache24/mod_pascal.so: Undefined symbol "operatingsystem_parameter_envp"
```
[See related issue](https://github.com/zamronypj/mod_pascal/issues/1)
