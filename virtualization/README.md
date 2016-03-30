# Automation of debian-setup.sh

### Configuration files management

- https://github.com/hercules-team/augeas/wiki/Path-expressions
- https://docs.saltstack.com/en/latest/ref/states/all/salt.states.file.html
- https://docs.ansible.com/ansible/list_of_files_modules.html
- https://puppetlabs.com/blog/why-puppet-isnt-a-file-management-tool

Use `conf.d` style configurations!


#### Configuration file patches

- by pkg
- by installed-version
- by config file

`diff -wu installed.conf new.conf`
