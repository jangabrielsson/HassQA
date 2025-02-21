return {                   -- Example of configuration file
  debug = { myflag = 88 }, -- debug flags, can be overriden with --%%debug directives in file
  creds = {
    user = "admin",             -- creds for accessing the HC3
    url = "http://192.168.1.57/"
  },
  secret="hysch",           -- Ex. --%%var=foo:config.secret, creates quickVar foo with value "hysch"
}
