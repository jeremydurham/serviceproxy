ServiceProxy
============

ServiceProxy is a lightweight SOAP library for Ruby. 

HOW IT WORKS
------------

GENERATING A PROXY
------------------

ServiceProxy comes with a simple generator to get started. It can be invoked
as follows:

wsdl2proxy [wsdl]

This will generate a file named default.rb, in the current directory. The class
will be named GeneratedService, and will define build and parse methods for all
of the available service methods, as well as add some boilerplate code to inspect
the available methods on the service. 

Rails Support
-------------

ServiceProxy does not have any dependencies on Rails or other frameworks, nor does
the generator.

Ruby 1.9 Support
----------------

ServiceProxy supports Ruby 1.9

USAGE
-----

Please refer to the specs for extended usage examples.

CONTRIBUTORS
------------

Rich Cavanaugh