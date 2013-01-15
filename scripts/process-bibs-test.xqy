xquery version "3.0";

(: IMPORTED MODULES :)
import module namespace file            =   "http://expath.org/ns/file";
import module namespace parsexml        =   "http://www.zorba-xquery.com/modules/xml";
import schema namespace parseoptions    =   "http://www.zorba-xquery.com/modules/xml-options";

(: NAMESPACES :)
declare namespace marcxml       = "http://www.loc.gov/MARC21/slim";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:omit-xml-declaration "yes";

let $dirpath := "../data/xml/"
let $files := file:list($dirpath, fn:false(), "*.xml")

let $data := 
	for $f in $files
	(: return fn:concat($dirpath, $f, "&#10;") :)
	let $raw-data as xs:string := file:read-text(fn:concat($dirpath, $f))
	let $records := 
        	parsexml:parse(
	            $raw-data, 
	            <parseoptions:options>
	                <parseoptions:parse-external-parsed-entity parseoptions:skip-root-nodes="1"/>
	            </parseoptions:options>
	         )
	let $lines := 
	    for $r at $pos in $records
	    return $pos 
	return $lines

return $data
