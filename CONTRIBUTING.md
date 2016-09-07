# Contributing

Thanks for your contribution to `knife-vsphere`. This project is used by lots of people to make their work days better, and it's great that you've chosen to help.

## Getting started

Note: You need a Ruby environment for this to work, preferably [Chef DK](https://downloads.chef.io/chef-dk/).

First fork the repo with the *fork* button at the top right of the screen.

Then check it out:

    git clone git@github.com:YOUR_USERNAME/knife-vsphere.git # or your fork
    cd knife-vsphere
    bundle install # only needs to be done once

Run the tests!

    bundle exec rake spec

You can run commands from your locally checked version by prefixing it with `bundle exec`
    bundle exec knife vsphere ...


## What's in scope and out of scope?

Virtually anything you can do in vcenter is fair game here. If we can save someone from needing a GUI for one more task, we're doing great work. Not everyone who uses this gem uses Chef, though. So integrations between the two are welcome, but don't assume Chef is present. A good example is `knife vsphere vm delete`, where it'll delete the node in VMWare and optionally the node/client inside Chef.

## Please please please...

* It would be great if you could write some tests to exercise the bug/feature you're working on. We use [RSpec](http://rspec.info/) and you can see [some examples](https://github.com/chef-partners/knife-vsphere/tree/master/spec). We're retroactively adding tests to an older code base, so we don't have anything approaching good coverage. But every little bit helps.
* Write a detailed commit message explaining why the feature is needed, link to any bug reports or external sites. It makes it easier later down the line to understand the behaviour you were going for. There are a lot of "WTF?" things in here and sometimes looking back at the git history is the only thing that tells us what is supposed to happen. Let's try not to add to that number
* Use descriptive variable and method names. Feel free to extract stuff to private methods to keep the main body shorter.
* Fix problems brought up by Hound. We use some automatic linting that will run on your pull request and ensure that the style is consistent.
* Add your new command to the README.

## Getting help

Feel free to file an issue for anything you find, or a question you have.

You can also find people on #rbvmomi on Freenode IRC, or join the [Chef Community Slack](http://community-slack.chef.io/).
