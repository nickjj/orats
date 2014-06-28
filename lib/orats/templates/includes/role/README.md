## What is repo_name? [![Build Status](https://secure.travis-ci.org/github_user/repo_name.png)](http://travis-ci.org/github_user/repo_name)

It is an [ansible](http://www.ansible.com/home) role to <enter what the role is about>.

### What problem does it solve and why is it useful?

Thanks for generating a role with orats. Here's your todo list:

- Change `meta/main.yml` to your liking
- Create your awesome role
- Fill out this readme properly
- Sign up for [travis-ci.org](http://travis-ci.org) (it is free for public repos)
- Review `.travis.yml` and write reasonable tests
- Push your role to github and tag it with a version number
- Publish your role on the [ansible galaxy](https://galaxy.ansible.com] if it's not private
- Replace the `role_id` with your id in the `Ansible galaxy` section of this readme

## Role variables

Below is a list of default values along with a description of what they do.

```
# Add your default role variables here.
```

## Example playbook

For the sake of this example let's assume you have a group called **foo** and you have a typical `site.yml` file.

To use this role edit your `site.yml` file to look something like this:

```
---
- name: ensure foo servers are configured
- hosts: foo

  roles:
    - { role: github_user.role_name, tags: role_name }
```

Let's say you want to edit a few values, you can do this by opening or creating `group_vars/foo.yml` which is located relative to your `inventory` directory and then making it look something like this:

```
---
# Overwrite the defaults here.
```

## Installation

`$ ansible-galaxy install github_user.role_name`

## Requirements

Tested on <enter your OS of choice>.

## Ansible galaxy

You can find it on the official [ansible galaxy](https://galaxy.ansible.com/list#/roles/role_id) if you want to rate it.

## License

MIT