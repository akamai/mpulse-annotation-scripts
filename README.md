## Introduction
This repository contains three utility scripts for working with [Akamai mPulse](https://www.akamai.com/us/en/products/web-performance/mpulse.jsp) annotations: one that creates annotations, one that deletes them, and one that retrieves (_gets_) them.
Internally, these scripts use the [Annotations REST API](http://docs.soasta.com/annotations-api/).

## Requirements
Each script requires:
* A valid mPulse account.
* An "API Token" that you can obtain from the mPulse UI, in Preferences.

## Creating Annotations
To **create** an annotation, you'll need the ID of the domain that the annotation should be attached to.  This ID can be obtained using the [Repository REST API](http://docs.soasta.com/repository-api/), or by contacting Akamai support.  The syntax is as follows:
```bash
$ ./create-annotation.sh -a INSERT_API_KEY -t INSERT_TITLE -d INSERT_DOMAIN_ID
```

For example, to create a "Hello world" annotation for the domain with ID 42, and the current timestamp, use the following:
```bash
$ ./create-annotation.sh -a abcde-1234-abcdefabcdef-5678 -t "Hello world" -d 42
```

The output will be the JSON response that was received from the Annotations REST API, and will include the ID of the newly-created annotation.  Example:
```json
{"id":169478}
```

### Notes
You can optionally assign annotations to multiple domains, instead of just one, by using a comma-separated list for the `-d` parameter value (e.g. `-d 42,43`).

Additional options:
* The `-b` parameter allows you to specify a body (description) in addition to the title.
* The `-m` parameter allows you to override the annotation timestamp.  The value should be in epoch milliseconds.  For example, to create an annotation for January 1st, 2017, at midnight Pacific Time, you would use `-m 1483257600000`.

## Deleting Annotations
To **delete** an annotation, you'll need the ID of the **annotation** (not the ID of the domain).  The syntax is as follows:
```bash
$ ./delete-annotation.sh -a INSERT_API_KEY -i INSERT_ANNOTATION_ID
```

For example, if the output from `create-annotation.sh` was `{"id":169478}`, then to delete that annotation, you would use the following:
```bash
$ ./delete-annotation.sh -a abcde-1234-abcdefabcdef-5678 -i 169478
```

## Retrieving Annotations
To **get** an annotation, you'll need the ID of the **annotation** (not the ID of the domain).  The syntax is as follows:
```bash
$ ./get-annotation.sh -a INSERT_API_KEY -i INSERT_ANNOTATION_ID
```

For example, if the output from `create-annotation.sh` was `{"id":169478}`, then to get that annotation, you would use the following:
```bash
$ ./get-annotation.sh -a abcde-1234-abcdefabcdef-5678 -i 169478
```

The output will be the JSON response that was received from the Annotations REST API, and will include the details of the annotation.  Example:
```json
{
  "id": 169478,
  "title": "Main upgraded to 59",
  "text": "",
  "start": 1506216097000,
  "source": "REST API",
  "type": "USER_ENTERED",
  "lastModified": 1506375712221,
  "user": "msolnit@akamai.com",
  "domains": [
    {
      "id": 42489,
      "name": "mPulse Snowflake Queries (Prod)"
    }
  ]
}
```

To **get** all annotations for a particular tenant, you'll need the teant name and a start timestamp in epoch milis.  The syntax is as follows:
```
$ ./get-annotation.sh -a INSERT_API_KEY -n INSERT_TENANT_NAME -b INSERT_START_TIMESTAMP
```

The output will be the JSON response that was received from the Annotations REST API, and will include the details of all of the annotations starting from the start.

You can also add an end timestamp to limit the results to a particular window of time and you can also specify a domain id to restrict results to a single mPulse app.


_For all of the scripts you can use the `-h` parameter to view a list of all the parameter options available for a given script._