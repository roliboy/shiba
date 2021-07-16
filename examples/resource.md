# resource

this file contains examples for using resources

## command structure
```
shiba resource <route> <resource-file>
```

`<route>` is the uri on which the server will listen for CRUD operations, `<resource-file>` is the local file where the JSON data is stored



## unstructured data
```
shiba resource /documents documents.json
```

has a default auto-incremented id field

accepts any fields and any data types

sending a POST request with the following JSON as payload: `{"title": "document title", "pages": 256}`, will append `{"id": 3}` to the object if the highest id in the resource file was 2



## required fields
```
shiba resource /documents documents.json [
        title
        pages
    ]
```

has a default auto-incremented id field

accepts any fields and any data types, fails if the fields declared on the model are not provided

sending a POST request with the following JSON as payload: `{"title": "document title"}`, will fail with "pages attribute is required"



## type constraints
```
shiba resource /documents documents.json [
        title:string
        pages:number
    ]
```

has a default auto-incremented id field

accepts any fields and any data types, fails if the fields declared on the model are not provided or have the wrong data type

sending a POST request with the following JSON as payload: `{"title": "document title", "pages": "245"}`, will fail with "pages attribute expected number but got string"



## type-constrained optional fields
```
shiba resource /documents documents.json [
        title:string
        ?author:string=unknown
    ]
```

has a default auto-incremented id field

accepts any fields and any data types, fails if the optional field is provided but has the wrong data type

sending a POST request with the following JSON as payload: `{"title": "document title", "author": 123}`, will fail with "author attribute expected string but got number"

sending a request without the pages attribute will create the entity successfully



## custom id field
```
shiba resource /documents documents.json [
        *isbn:string
        title:string
        pages:number
    ]
```

no default auto-incremented id field, uses the specified attribute instead

accepts any fields and any data types, fails if the fields declared on the model are not provided or have the wrong data type

when performing retrieve/update/delete operations, the uri path variable will use the value of the custom id field
