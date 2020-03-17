# mod_pascal

Apache 2.4 module implementation which is capable to execute Pascal program just like scripting language.

## Requirement

- [Free Pascal compiler](https://www.freepascal.org)
- [Apache 2.4](https://httpd.apache.org/docs/2.4/)

## Setup

### Compile mod_pascal

```
$ git clone https://github.com/zamronypj/mod_pascal.git
$ cd mod_pascal && ./setup.cfg.sh && ./build.sh
```

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

It is important that you use `pascal_module` to identify mod_pascal module and
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

Open URL http://localhost/test.pas from Internet browser, you should see text `Hello from Pascal` printed in browser.

If `test.pas` is downloaded then you do not register mod_pascal with Apache correctly.

To return response with header, add header line separated by newline

```
begin
    writeln('Content-Type : text/html');
    writeln();
    writeln('<h1>Hello from Pascal</h1>');
end.
```

Please note that because blank newline is used to mark end of header parts of response, for safety, always add them even if you do not want to set response header. For example

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

## More module configuration

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