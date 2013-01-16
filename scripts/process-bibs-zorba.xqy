xquery version "3.0";

(:
:   Module Name: Extract LCSH data from MARC bibs
:
:   Module Version: 1.0
:
:   Date: 2012 January 13
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: saxon (Saxon)
:
:   Xquery Specification: January 2007
:
:   Module Overview:     Extracts LCSH data from MARC
:       Bibs formatted for loading into a database (MySQL).
:
:   Run: zorba -i -q file:///location/of/zorba.xqy -e marcxmluri:="http://location/of/marcxml.xml" -e serialization:="rdfxml" -e baseuri:="http://your-base-uri/"
:   Run: zorba -i -q file:///location/of/zorba.xqy -e marcxmluri:="../location/of/marcxml.xml" -e serialization:="rdfxml" -e baseuri:="http://your-base-uri/"
:)

(:~
:   Transforms MARC/XML Bibliographic records
:   to RDF conforming to the BIBFRAME model.  Outputs RDF/XML,
:   N-triples, or JSON.

# bibid  (record this even if no subjects?)
# lccn
# Heading, as written, with hyphens
# Heading, remove all punctuation
# how many components
# types of components - topic, geographic, temporal, genre/form
# subfield order usage, avxv for example

# How many subject headings
# How many total resources
# How many total resources without subjects
# How many *unique* subject headings
# Greatest number of components
# Frequency of components % topic, % geographic, % temporal, % genre/form

# 600, 610, 611, 630, 648, 650, 651
# Second indicator = 2

CREATE TABLE subjects (
  `id` bigint(17) unsigned NOT NULL auto_increment,
  `bibid` char(10) NOT NULL,
  `lccn` char(10) NOT NULL,
  `heading` char(254) NOT NULL,
  `headingStripped` char(254) NOT NULL,
  `source` char(30) NOT NULL,
  `field` smallint(3) NOT NULL,
  `subfields` char(20) NOT NULL,
  `componentsCount` tinyint(2) NOT NULL,
  `subdivsCount` tinyint(2) NOT NULL,
  `vCount` tinyint(2) NOT NULL,
  `xCount` tinyint(2) NOT NULL,
  `yCount` tinyint(2) NOT NULL,
  `zCount` tinyint(2) NOT NULL,
  PRIMARY KEY  (`id`),
  INDEX (headingStripped),
  INDEX (source),
  INDEX (field),
  INDEX (subfields),
  INDEX (componentsCount),
  INDEX (subdivsCount),
  INDEX (vCount),
  INDEX (xCount),
  INDEX (yCount),
  INDEX (zCount)
) ENGINE=MYISAM DEFAULT CHARSET="UTF8";

# ALTER TABLE subjects ADD INDEX (subfields);

select headingStripped, count(*) as hsCount from subjects group by headingStripped HAVING hsCount > 2 order by hsCount DESC LIMIT 0,10;
SELECT hsCount, count(*) FROM (select headingStripped, count(*) as hsCount from subjects group by headingStripped) as tempTBL group by hsCount;

select componentsCount, count(*) from subjects group by componentsCount order by componentsCount DESC;

http://dev.mysql.com/doc/refman/5.1/en/create-table-select.html

:
:   @author Kevin Ford (kefo@loc.gov)
:   @since December 03, 2012
:   @version 1.0
:)

(: IMPORTED MODULES :)
import module namespace http            =   "http://www.zorba-xquery.com/modules/http-client";
import module namespace file            =   "http://expath.org/ns/file";
import module namespace parsexml        =   "http://www.zorba-xquery.com/modules/xml";
import schema namespace parseoptions    =   "http://www.zorba-xquery.com/modules/xml-options";

import module namespace processrecord   = 'info:lc/id-bibframe/processrecord#' at "module.ProcessRecord.xqy";

(: NAMESPACES :)
declare namespace marcxml       = "http://www.loc.gov/MARC21/slim";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:omit-xml-declaration "yes";

(:~
: This variable is for the MARCXML location - externally defined.
:)
declare variable $marcxmluri as xs:string external;

let $savefile := "../data/tsv/subjects.tsv"

let $raw-data as xs:string := file:read-text($marcxmluri)
let $records := 
        parsexml:parse(
            $raw-data, 
            <parseoptions:options>
                <parseoptions:parse-external-parsed-entity parseoptions:skip-root-nodes="1"/>
            </parseoptions:options>
         )
let $lines := 
    for $r at $pos in $records
    return processrecord:processrecord($r)

let $fwrite := 
    file:append(
        $savefile, 
        fn:concat(fn:string-join($lines, "&#10;"), "&#10;"),
        <output:serialization-parameters>
            <output:method value="text" />
            <output:omit-xml-declaration value="yes" />
        </output:serialization-parameters>
    )
    
return fn:concat("Processed ", fn:count($lines), " subjects in ", $marcxmluri)

