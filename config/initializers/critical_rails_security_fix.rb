# See https://community.rapid7.com/community/metasploit/blog/2013/01/09/serialization-mischief-in-ruby-land-cve-2013-0156?x=1

ActiveSupport::XmlMini::PARSING.delete("symbol") 
ActiveSupport::XmlMini::PARSING.delete("yaml") 
