# command

this file contains examples for using commands

## command structure
```
shiba command <route> <command>
```

`<route>` is the uri on which the command can be accessed, `<command>` is the inline command or executable



## passing input
```
shiba command /wordcount 'wc -w'
```

the body of the http request is passed to the command as `stdin`

when sending `good boie shiba` as request body, the server will respond with `3`

`curl -X POST localhost:1337/wordcount -d 'good boie shiba'`



## passing command line arguments
```
shiba command /drop/{table} ./dropit
```

uri variables are used as command line arguments (in the order of their occurence)

sending a request to `/drop/users` will invoke the script with `users` as parameter: `./dropit users`



## environment variables
```
shiba command /motd ./motd
```

suppose you want to perform different actions based on the http request method

motd is a script that will return the message of the day if the request method used was GET, and set the message if the POST method was used

the folowing variables are exported before invoking the command
- SHIBA_REQUEST_METHOD: GET, POST etc. (even non-standard methods)
