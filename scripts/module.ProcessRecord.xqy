xquery version "1.0";

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
  `source` char(20) NOT NULL,
  `field` int(3) NOT NULL,
  `subfields` char(12) NOT NULL,
  `componentsCount` int(1) NOT NULL,
  `subdivsCount` int(1) NOT NULL,
  `vCount` int(1) NOT NULL,
  `xCount` int(1) NOT NULL,
  `yCount` int(1) NOT NULL,
  `zCount` int(1) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MYISAM DEFAULT CHARSET="UTF8";

select headingStripped, count(*) as hsCount from subjects group by headingStripped HAVING hsCount > 2 order by hsCount DESC LIMIT 0,10;
SELECT hsCount, count(*) FROM (select headingStripped, count(*) as hsCount from subjects group by headingStripped) as tempTBL group by hsCount;


:
:   @author Kevin Ford (kefo@loc.gov)
:   @since December 03, 2012
:   @version 1.0
:)

(: IMPORTED MODULES :)
module namespace processrecord  = 'info:lc/id-bibframe/processrecord#';

(: NAMESPACES :)
declare namespace marcxml       = "http://www.loc.gov/MARC21/slim";

declare function processrecord:processrecord
        ($record)
        as item()*
{
    let $df001 := xs:string($record/marcxml:controlfield[@tag eq "001"][1])
    let $df010 := xs:string($record/marcxml:controlfield[@tag eq "010"][1]/marcxml:subfield[@code eq "a"][1])
    let $subjects := $record/marcxml:datafield[fn:matches(xs:string(@tag), "600|610|611|630|648|650|651|655")]
    let $lines := 
        for $s at $pos in $subjects
        let $tag := xs:string($s/@tag)
        let $id := fn:replace($df001, "([a-zA-Z])", "")
        
        let $idLen := fn:string-length($id)
        let $paddedID :=
            if ( $idLen eq 1 ) then
                fn:concat("10000000000" , $id)
            else if ( $idLen eq 2 ) then
                fn:concat("1000000000" , $id)
            else if ( $idLen eq 3 ) then
                fn:concat("100000000" , $id)
            else if ( $idLen eq 4 ) then
                fn:concat("10000000" , $id)
            else if ( $idLen eq 5 ) then
                fn:concat("1000000" , $id)
            else if ( $idLen eq 6 ) then
                fn:concat("100000" , $id)
            else if ( $idLen eq 7 ) then
                fn:concat("10000" , $id)
            else if ( $idLen eq 8 ) then
                fn:concat("1000" , $id)
            else if ( $idLen eq 9 ) then
                fn:concat("100" , $id)
            else if ( $idLen eq 10 ) then
                fn:concat("10" , $id)
            else if ( $idLen eq 11 ) then
                fn:concat("1" , $id)
            else
                $id
                
        let $posid := xs:string($pos)
        let $posidLen := fn:string-length($posid)
        let $paddedPosID :=
            if ( $posidLen eq 1 ) then
                fn:concat("000" , $posid)
            else if ( $posidLen eq 2 ) then
                fn:concat("00" , $posid)
            else if ( $posidLen eq 3 ) then
                fn:concat("0" , $posid)
            else
                $posid
        
        let $id := fn:concat($paddedID, $paddedPosID)
        let $aplus := fn:string-join($s/marcxml:subfield[fn:not( fn:matches(@code, "v|x|y|z|0|2|3|4|6|8") )], " ")
        let $subdivisionString := fn:string-join($s/marcxml:subfield[fn:matches(@code, "v|x|y|z")], "--")
        let $heading := 
            if ($subdivisionString ne "") then
                fn:concat($aplus, "--", $subdivisionString)
            else
                $aplus
        let $headingStripped := fn:replace($heading, " |\.|\(|\)|,|:", "")
        let $headingStripped := fn:replace($headingStripped, '"', "")
        let $headingStripped := fn:replace($headingStripped, '\[fromoldcatalog\]', "")
        
        let $ind2 := xs:string($s/@ind2)
        let $source := 
            if ($ind2 eq "0") then
                "lcsh"
            else if ($ind2 eq "1") then
                "lcshj"
            else if ($ind2 eq "2") then
                "mesh"
            else if ($ind2 eq "3") then
                "nal"
            else if ($ind2 eq "4") then
                "not-specified"
            else if ($ind2 eq "5") then
                "lac"
            else if ($ind2 eq "6") then
                "rvm"
            else if ($ind2 eq "7") then
                let $sf2 := xs:string($s/marcxml:subfield[xs:string(@code) eq "2"][1])
                return $sf2
            else 
                ""
        
        let $fieldOrder := fn:string-join($s/marcxml:subfield[fn:matches(@code, "a|t|v|x|y|z")]/@code, "")
        
        let $componentsCount := fn:count($s/marcxml:subfield[fn:matches(@code, "a|t|v|x|y|z")])
        let $subdivsCount := fn:count($s/marcxml:subfield[fn:matches(@code, "v|x|y|z")])
        
        let $subdivVcount := fn:count($s/marcxml:subfield[fn:matches(@code, "v")])
        let $subdivXcount := fn:count($s/marcxml:subfield[fn:matches(@code, "x")])
        let $subdivYcount := fn:count($s/marcxml:subfield[fn:matches(@code, "y")])
        let $subdivZcount := fn:count($s/marcxml:subfield[fn:matches(@code, "z")])
        return
            fn:concat($id, "&#09;", $df001, "&#09;", $df010, "&#09;", $heading, "&#09;", $headingStripped, "&#09;", $source, "&#09;", $tag, "&#09;", $fieldOrder, "&#09;", $componentsCount, "&#09;", $subdivsCount, "&#09;", $subdivVcount, "&#09;", $subdivXcount, "&#09;", $subdivYcount, "&#09;", $subdivZcount)
    return $lines
};
