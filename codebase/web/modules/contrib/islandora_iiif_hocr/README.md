# Islandora IIIF hOCR

## Introduction

This module is part of the Islandora project and extends the Islandora IIIF component module
to support IIIF search results annotations. This provides the back-end support for
on-page highlighting of search results within image viewers such as [Mirador](https://github.com/ProjectMirador/mirador)
via the [Islandora Mirador](https://github.com/islandora/islandora_mirador) module.

## Installation

Include with `composer require born-digital/islandora_iiif_hocr`

### Configuring Search Highlighting annotations

Although it is not expressed as a hard requirement, this module assumes tue use of https://github.com/discoverygarden/islandora_hocr, including the installation and configuration of the [solr-ocrhighlighting](https://github.com/dbmdz/solr-ocrhighlighting) Solr plugin.

### Usage

The module provides a Views style plugin to format the results of a Search API Solr response
in IIIF annotation format. Thus setting it up requires
a search view be created.
A sample search view is located in the config/optional folder of
this module.

The important parts are:

- Create a Media view and set the formatter to 'IIIF Search Result Annotations'.
- In the style plugin settings, choose the Media Use term that is configured in the IIIF Manifest
that this search will be attached to. Usually 'Service File' or 'Original File'.
- Add a search filter for the hOCR, 'Fulltext hOCR search (and )' field.
    In this filter's settings, thSet the Filter Identifier field to "search_hocr".
- Set a sort criteria, eitehr Relevance or, to make results appear in page order,, field_weight.
- Set a path with a'%node' component to be the search endpoint.
    e.g., paged-content-search/%node.
    Note this path as it's needed back in the IIIF Manifest view settings.
- Add a Contextual Filter for 'Content datasource: Member of'. This restricts the search
        to the book that the search is being done on.
- Under query settings, set 'the Query Tag field to 'enable_hocr'.
        This is important as it tells this module to add hOCR-specific
        parameters to the search query.
- Add another display for Single Item search, and leave off the contextual filter, so only the single node
    is searched.

After saving the view, it can be tested by going directly to the path endpoint
with a search parameter added, e.g., paged-content-search/%[some-book-nid]]?search_query_param="My search"

To make Mirador be able to do searches, go back to the views settings
for the IIIF Manifest, and edit the IIIF Manifest style plugin settings.

There is now a field for setting the search endpoint that Mirador (or another viewer that supports IIIF Search) should use.[^1] Put in the path you set above, including %node, and save.*

[^1]: Pending the merge of https://github.com/Islandora/islandora/pull/983



## Documentation

Further documentation for IIIF (International Image Interoperability Framework) is available on the [Islandora 8 documentation site](https://islandora.github.io/documentation/user-documentation/iiif/).

## Troubleshooting/Issues

Having problems? Solved a problem? Join the Islandora [communication channels](https://www.islandora.ca/community#channels-of-communication) to post questions and share solutions:

* [Islandora Mailing List (Google Group)](https://groups.google.com/g/islandora)


* If you would like to contribute or have questions, please get involved by attending our weekly [Tech Call](https://github.com/Islandora/islandora-community/wiki/Weekly-Open-Tech-Call), held virtually via Zoom **every Wednesday** at [**1:00pm Eastern Time US**](https://dateful.com/convert/est-edt-eastern-time?t=13). Anyone is welcome to join and ask questions! The Zoom link can be found in the meeting minutes [here](https://github.com/Islandora/islandora-community/wiki/Weekly-Open-Tech-Call).

If you would like to contribute code to the project, you need to be covered by an Islandora Foundation [Contributor License Agreement](https://github.com/Islandora/islandora-community/wiki/Onboarding-Checklist#contributor-license-agreements) or [Corporate Contributor License Agreement](https://github.com/Islandora/islandora-community/wiki/Onboarding-Checklist#contributor-license-agreements). Please see the [Contributor License Agreements](https://github.com/Islandora/islandora-community/wiki/Contributor-License-Agreements) page on the islandora-community wiki for more information.


## License

[GPLv2](http://www.gnu.org/licenses/gpl-2.0.txt)
