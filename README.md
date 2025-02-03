# mi-core-pixelfed

This repository is based on [Joyent mibe](https://github.com/joyent/mibe). Please note this repository should be build with the [mi-core-base](https://github.com/skylime/mi-core-base) mibe image.

## description

This image provides [PixelFed](https://github.com/pixelfed) a federated image sharing for everyone!

A admin user is automatically created and stores the password in mdata. It's recommended to set a admin email address via metadata but is not required.

## mdata variables

No mdata variable is required. Everything could be automatically generated on
provision state.

- `ngxin_ssl`: ssl certificate for the web interface (default: Let's Encrypt)
- `pixelfed_app_name`: name of your application (shown via html title)
- `pixelfed_admin_mail`: email address of the admin user (default: `admin@localhost`)

## services

- `80/tcp`: http webserver
- `443/tcp`: https webserver
