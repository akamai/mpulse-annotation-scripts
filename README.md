## Introduction
This repository contains two utility scripts for working with [Akamai mPulse](https://www.akamai.com/us/en/products/web-performance/mpulse.jsp) annotations: one that creates annotations, and one that deletes them.
Internally, these scripts use the [Annotations REST API](http://docs.soasta.com/annotations-api/).

## Requirements
Each script requires:
* A valid mPulse account.
* An "API Token" that you can obtain from the mPulse UI, in Preferences.

## Creating Annotations
To **create** an annotation, you'll need the ID of the domain that the annotation should be attached to.  This ID can be obtained using the [Repository REST API](http://docs.soasta.com/repository-api/), or by contacting Akamai support.  The syntax is as follows:
```
$ ./create-annotation.sh -a INSERT_API_KEY -t INSERT_TITLE -d INSERT_DOMAIN_ID
```

For example, to create a "Hello world" annotation for the domain with ID 42, and the current timestamp, use the following:
```
$ ./create-annotation.sh -a abcde-1234-abcdefabcdef-5678 -t "Hello world" -d 42
```

The output will be the JSON response that was received from the Annotations REST API, and will include the ID of the newly-created annotation.  Example:
```
{"id":169478}
```

### Notes
You can optionally assign annotations to multiple domains, instead of just one, by using a comma-separated list for the `-d` parameter value (e.g. `-d 42,43`).

Additional options:
* The `-b` parameter allows you to specify a body (description) in addition to the title.
* The `-m` parameter allows you to override the annotation timestamp.  The value should be in epoch milliseconds.  For example, to create an annotation for January 1st, 2017, at midnight Pacific Time, you would use `-m 1483257600000`.

## Deleting Annotations
To **delete** an annotation, you'll need the ID of the **annotation** (not the ID of the domain).  The syntax is as follows:
```
$ ./delete-annotation.sh -a INSERT_API_KEY -i INSERT_ANNOTATION_ID
```

For example, if the output from `create-annotation.sh` was `{"id":169478}`, then to delete that annotation, you would use the following:
```
$ ./delete-annotation.sh -a abcde-1234-abcdefabcdef-5678 -i 169478
```
