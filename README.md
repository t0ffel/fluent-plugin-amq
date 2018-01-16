# fluent-plugin-amqp
AMQP Qpid input plugin for fluentd

## Overview

Fluentd plugin to listen to secured AMQP message bus.

## Why this plugin was created?

The plugin allows listening to the AMQP message bus and forward the events to other systems.

At the moment the plugin only works for secure AMQP (amqps://).

## Dependencies

This plugin uses `qpid_proton` to support AMQP.

## Installation

You need to install Qpid proton libraries before installing this plugin (RedHat/CentOS)
```
  # yum install qpid-proton-c qpid-proton-c-devel
  # fluent-gem install fluent-plugin-amqp
```
## Configuration

Here is the sample configuration of the plugin

    <source>
      @type amqp
      url amqps://messaging:5671
      tag prefix.tag
      queue Consumer.client.myclient.VirtualTopic.>
      cert /home/centos/cert.crt
      private_key /home/centos//cert.key
    </source>

* `url` is the URL of the AMQP broker.
* `tag` will prefix the topic name from the message, the resulting string will be the tag.
* `queue` is the queue to subscribe to
* `cert` is the path to the certificate to authenticate to the broker
* `private_key` is the path to the private key for the `cert`

## Copyright

* Copyright (c) 2018- Anton Sherkhonov
* License
  * Apache License, Version 2.0
