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

ServiceProxy does not have any dependencies on Rails or other frameworks, nor does
the generator.

Please refer to the specs for extended usage examples.

CONTRIBUTORS
------------

Rich Cavanaugh