public with sharing class CSVUtility{

    /*
    This is a utility class I (PT) have been in need of for 2 reasons:
        - loading data into salesforce 
        - getting csv files out as a result of manipulated data. 
    Reports can't do the operations I sometimes need to do to join data, so I would like to create an sObject list 
        or list of maps, then export them  
    
    The class has 2 entry points when exporting, one entry point when importing. 
    Exporting: 
        -  sObjectListToCSVFile: Pass in a list of sObject
        -  mapListToCSVFile: pass in a list maps, each map is a row
    Importing: 
        - CSVContentDocumentIdToMapList: pass in the contentDocumentId of your csv file, get back a list of maps 

    A string representation of a csv is expected to have the first row as headers, followed by all value rows 
    like this 
    header1,header2,header3\n
    val1,val2,val3\n
    vala,valb,valc\n
    */

    // ----------- Exporting entry points -----------
    public static id sObjectListToCSVFile(List<sObject> sObjectList, string resultFilename){
        /*
        Provided a list of sObjects (representing each row in the resulting csv), creates a .csv file, returns the ID
        */
        list<Map<string, Object>> mapList = sObjectListToMapList(sObjectList);
        return(mapListToCSVFile(mapList, resultFilename));
    }

    public static id mapListToCSVFile(list<Map<string, Object>> mapList, string resultFileName){
        /*
        Provided a list of maps (representing each row in the resulting csv, creates a .csv file and returns the ID)
        */
        resultFilename = resultFileName.substringBeforeLast('.csv');
        string csvString = mapListToCSVString(mapList);
        return(csvStringToContentDocument(csvString, resultFilename));
    }

    
    // ----------- Importing entry points -----------
    public static list<map<string, Object>> CSVContentDocumentIdToMapList(Id CSVContentDocumentId){ //TODO, these don't look like json, so deserialise is pointless 
        /*
        provided a cd id, reads it, parses it, returns a list of maps, representing each row 
        */
        string fileString = cdIdToString(CSVContentDocumentId);
        list<map<string, Object>> returnList = csvStringToMapList(fileString);
        return(returnList);
    }


    // ---------- Don't look behind this curtain ---------------
    public static list<Map<String, Object>> csvStringToMapList(string csvString){
        /*
        #### Inputs:
            -@csvString: string representation of a csv (see top of file for format)
        #### Expected Behaviour:
            - Loads each row, turns each one into a map with the headers as keys. These are combined into the returned list
        #### Returns:
            - list of maps, each map being a row in the csv
        */
        list<string> lines = csvString.split('\n');
        list<string> headerList = lines[0].split(',');
        lines.remove(0);
        list<Map<string, Object>> returnList = new list<Map<string, Object>>();
        for(string line: lines){
            returnList.add(headerListAndRowStringToRowMap(headerList, line));
        }
        return(returnList);
    }

    
    public static map<String, Object> headerListAndRowStringToRowMap(list<string> headers, string rowString){
        /*
        #### Inputs:
            -@headers: list of headers from first row of csv string 
            -@rowString: single row without the newline
        #### Expected Behaviour: 
            - rowstring is split on ',', then for each header we assume the corresponding index    
                in the split rowString list is the value for that key. These are put together in the map 
        #### Returns:
            - map representation of the rowString, using the headers as keys
        */
        list<string> rowVals = rowString.split(',');
        map<string, Object> returnMap = new map<string, Object>();
        for(Integer i = 0; i < headers.size(); i++){
            returnMap.put(headers[i], rowVals[i]);
        }
        return(returnMap);
    }


    public static list<Map<string, Object>> sObjectListToMapList(list<sObject> sObjectList){
        /*
        #### Inputs:
            -@sObjectList: list of sobjects 
        #### Expected Behaviour:
            - Utility to be used to facilitate the conversion of an SobjectList to an intermediate 
                map, then this can be turned to a string and saved in a file
            - because sObjects as a result of a query have the 'attributes' field populated, delete this when casting to a list of maps 
        */
        string serialized = json.serialize(sObjectList);
        system.debug(serialized);
        list<Object> rawList = (list<Object>) json.deserializeUntyped(serialized);
        list<map<string, Object>> serializedObjectList = new list<map<string,Object>>();
        for (Object row : rawList) {
            Map<String, Object> castRow = (Map<String, Object>) row;
            castRow.remove('attributes');
            serializedObjectList.add((map<string, Object>) row);
        }
        return(serializedObjectList);
    }


    public static string mapListToCSVString(list<Map<string, Object>> mapList){
        /*
        #### Inputs:
            -@sObjectList: list of records as the result of a query 
            -@resultFilename: filename (without csv at end)
        #### Expected Behaviour:
            - Creates a string representation of the map list
            - each map in the list is a row, with their keys combined into a superset and used as the header row 
        #### Returns:
            - csv string, ready to be saved as the contents of a file 
        */
        set<string> headerSet = new set<String>();
        for(map<string, Object> currentRow: mapList){
            for(string key: currentRow.keyset()){
                headerSet.add(key);
            }
        }
        string csvString = headerSetToString(headerSet);
        for(Map<string, object> currentRow: mapList){
            csvString += mapToRowString(headerSet, currentRow);
        }
        return(csvString);
    }

    
    public static string headerSetToString(set<string> headerSet){
        /*
        #### Inputs:
            -@headerSet: set of headers (strings to name each column)
        #### Expected Behaviour:
            - return the headers are a comma separated string with a newline at the end
        #### Returns:
            - string to be used as the first line in the csv 
        */
        return(string.join(headerSet, ',') + '\n');
    }


    public static string mapToRowString(set<string> headerSet, map<string, Object> rowMap){
        /*
        #### Inputs:
            -@rowMap: a map representing a single object (which will result in a single row in the csv)
        #### Expected Behaviour:
            - for each row in the resulting file it needs a column for each header,
            - so for the incoming row we loop through the headers, if there's a corresponding value in the row map
                we add it in to the returned string, otherwise add an empty space
            - for each value in the set, if it's in the rowMap it's added to the row, otherwise an empty value 
                is added in that column 
        #### Returns:
            - String, representing one row in a csv
        */
        list<string> rowList = new list<string>();
        for(string header: headerSet){
            if(rowMap.containsKey(header)){
                rowList.add(string.valueOf(rowMap.get(header))); 
            }
            else{
                rowList.add(' ');
            }
        }
        return(string.join(rowList, ',') + '\n'); 
    }


    public static id csvStringToContentDocument(string csvString, string resultFilename){
        /*
        #### Inputs:
            -@csvString: expected to be string output of mapListToCSVString
            -@resultFilename: filename (without .csv)
        #### Expected Behaviour:
            - saves incoming string into a csv file of format <resultFilename>.csv
        #### Returns:
            - id of resulting ContentDocument
        */
        ContentVersion cv = new ContentVersion(
            Title = resultFilename,
            PathOnClient = resultFilename + '.csv',
            VersionData = Blob.valueOf(csvString),
            IsMajorVersion = true
        );
        insert(cv);
        cv = [select id, contentDocumentId from contentVersion where id=:cv.id];
        return(cv.ContentDocumentId);
    }


    public static string cdIdToString(Id cdId){
        /*
        #### Functions:
            -@cdId: contentDocument id, expected to be a .csv file
        #### Expected Behaviour:
            - Loads up the contentVersion file data, casts it to a string and returns it
            - if the incoming file isn't a .csv, an exception is thrown 
        #### Returns:
            - String contents of the given cdId file
        */
        contentVersion cv = [select id, PathOnClient, versionData from contentVersion where contentdocumentId=:cdId];
        if(!cv.PathOnClient.endsWithIgnoreCase('.csv')){
            throw new StringException(string.format('Found filename "{0}", function only accepts .csv extension files', new list<string>{cv.PathOnClient}));
        }
        string fileString = cv.versionData.toString();
        return(fileString);
    }

}