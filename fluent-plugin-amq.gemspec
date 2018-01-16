# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
    s.name              = "fluent-plugin-amq"
    s.version           = "0.0.1"
    s.authors           = ["Anton Sherkhonov"]
    s.email             = ["sherkhonov@gmail.com"]
    s.homepage          = "https://github.com/t0ffel/fluent-plugin-amq"
    s.summary           = "AMQP Qpid input plugin for fluentd"
    s.description       = %q"AMQP Qpid input plugin for fluentd"

    s.files             = `git ls-files`.split($\)
    s.executables       = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
    s.test_files        = s.files.grep(%r{^(test|spec|features)/})
    s.require_paths     = ["lib"]

    s.add_development_dependency "rake", '~> 0'
    s.add_runtime_dependency "qpid_proton", '~> 0.19'
    s.add_runtime_dependency "fluentd", '>= 0.12'
end
