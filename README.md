# mod_pascal

Apache 2.4 module implementation which is capable to execute Pascal program just like scripting language. [Read mod_pascal documentation](https://zamronypj.github.io/mod_pascal).

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
