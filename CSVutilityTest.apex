@isTest 
public class CSVUtilityTest{

    // cdIdToString tests --- 
    @isTest 
    public static void testCdIdToStringNonCSV(){
        /*
        #### Function:
            - CSVUtility.cdIdToString 
        #### Inputs:
            -@cdId: ContentDocument id, it's not a .csv
        #### Expected Behaviour:
            - The pathOnClient isn't a .csv, exception raised
        #### Assertions: 
            - The expected exception is thrown
        */
        // Setup ----
        ContentVersion cv1 = new ContentVersion(Title = 'Test Document 1', PathOnClient = 'TestDoc1.pdf', VersionData = Blob.valueOf('Test content 1'));
        insert(cv1);
        cv1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id LIMIT 1];
        // Test -----
        String exceptionString; 
        try{
            CSVUtility.cdIdToString(cv1.ContentDocumentId);
        }
        catch(Exception E){
            exceptionString = E.getMessage();
        }
        // Assert -----
        Assert.areEqual('Found filename "TestDoc1.pdf", function only accepts .csv extension files', exceptionString);
    }

    @isTest 
    public static void testCdIdToString(){
        /*
        #### Function:
            - CSVUtility.cdIdToString 
        #### Inputs:
            -@cdId: ContentDocument id, it IS a .csv
        #### Expected Behaviour:
            - The pathOnClient is a .csv, exception NOT raised, 
            - the versionData string is not returned
        #### Assertions: 
            - The expected string is returned
        */
        // Setup ----
        ContentVersion cv1 = new ContentVersion(Title = 'Test Document 1', PathOnClient = 'TestDoc1.csv', VersionData = Blob.valueOf('Test content 1'));
        insert(cv1);
        cv1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id LIMIT 1];
        // Test -----    
        String respString = CSVUtility.cdIdToString(cv1.ContentDocumentId);
        // Assert ---- 
        Assert.areEqual('Test content 1', respString);
    }

    
    //  csvStringToContentDocument tests -----
    @isTest 
    public static void testCSVStringToContentDocument(){
        ///Test ----
        Id respId = CSVUtility.csvStringToContentDocument('testdata', 'resultName');
        // Assert ---- 
        contentDocument cd = [select id, title from contentDocument where id=:respId];
        Assert.areEqual('resultName', cd.Title);
    }


    // mapToRowString tests ----
    @isTest 
    public static void testMapToRowString(){
        /*
        #### Function:
            - CSVUtility.mapToRowString
        #### Inputs:
            -@headerSet: set of strings 
            -@rowMap: map that has a subset of the headerSet
        #### Expected Behaviour:
            - the headers are looped through, one isn't present in the map so 
                a blank value is put in this place, string returned
        #### Assertions:
            - the expected string is returned 
        */
        // Setup --- 
        Set<String> inputSet = new set<String>{'header1', 'header2', 'header3', 'header4'};
        Map<string, Object> inputMap = new map<String, Object>{
            'header1'=>1,
            'header2'=>'val',
            'header4'=>'something'
        };
        // test ---
        String respString = CSVUtility.mapToRowString(inputSet, inputMap);
        // Assert --- 
        String expectedString = '1,val, ,something\n';
        Assert.areEqual(expectedString, respString); 
    }


    /// headerSetToString tests ----
    @isTest 
    public static void testHeaderSetToString(){
        /*
        #### Function:
            - CSVUtility.mapToRowString
        #### Inputs:
            -@headerSet: set of strings
        #### Expected Behaviour:
            - The set is joined and a newline is added 
        #### Assertions:
            - The expected string is returned
        */
        /// Setup ----
        set<String> headerSet = new set<String>{'key1', 'key2', 'key3'};
        /// Test --- 
        String respString = CSVUtility.headerSetToString(headerSet);
        /// Assert ---
        Assert.areEqual('key1,key2,key3\n', respString);
    }

    
    /// mapListToCSVString tests ---
    @isTest 
    public static void testMapListToCSVString(){  // TODO, complete these test comments 
        /*
        one row has all the values, one doesn't, then another does 
        */
        // Setup ---
        list<Map<string, Object>> mapList = new List<Map<string, Object>>{
            new map<string, Object>{
                'key1'=>1,
                'key2'=>'2',
                'key3'=>3
                },
            new map<string, Object>{
                'key1'=>'a',
                'key3'=>'c'
            },
            new map<string, Object>{
                'key1'=>'test1',
                'key2'=>'test2',
                'key3'=>'test3'
            }
        };
        /// Test ---- 
        String respString = CSVUtility.mapListToCSVString(mapList);
        /// Assert ---
        String expectedString = 'key1,key2,key3\n1,2,3\na, ,c\ntest1,test2,test3\n';
        Assert.areEqual(expectedString, respString);
    }


    /// sObjectListToMapList tests ---
    @isTest 
    public static void testsObjectListToMapList(){
        /*

        */
        // Setup ----
        contact a = new contact(firstname= 'f1', lastname='l1', email='123@mail.com');
        contact b = new contact(firstname= 'f2', lastname='l2', email='234@mail.com');
        contact c = new contact(firstname= 'f3', lastname='l3');
        list<contact> contactList = new list<Contact>{a, b, c};
        insert(contactList);
        contactList = [select firstname, lastname, email from contact];
        // Test -----
        List<Map<String, object>> respList = CSVUtility.sObjectListToMapList(contactList);
        // Assert ---- 
        Set<Map<string, Object>> respSet = new Set<Map<string, Object>>();
        for(map<String, Object> resp: respList){
            respSet.add(resp);
        }
        List<Map<String, Object>> expectedList = new List<Map<string, Object>>{
            new map<String, Object>{'FirstName'=>'f1', 'LastName'=>'l1', 'Email'=>'123@mail.com', 'Id'=>string.valueOf(a.id)},
            new map<String, Object>{'FirstName'=>'f2', 'LastName'=>'l2', 'Email'=>'234@mail.com', 'Id'=>string.valueOf(b.Id)},
            new map<String, Object>{'FirstName'=>'f3', 'LastName'=>'l3', 'Id'=>String.valueOf(c.Id)}
        };
        system.debug(respList);
        system.debug(expectedList);
        system.debug(expectedList.equals(respList));
        Assert.areEqual(expectedList, respList);
    }


    /// --- headerListAndRowStringToRow

    @isTest 
    public static void testHeaderListAndRowStringToRowMap(){
        /*
        #### Function:
            - CSVUtility.headerListAndRowStringToRowMap
        #### Inputs:
            -@headers: list of header strings from the first row of a csv
            -@rowString: a single csv row (no newline) with one value per header
        #### Expected Behaviour:
            - The rowString is split on ',', and each header is paired with the
                value at the corresponding index to build a map
        #### Assertions:
            - The returned map pairs each header with its matching row value
        */
        // Setup ---
        list<String> headers = new list<String>{'header1', 'header2', 'header3'};
        String rowString = 'val1,val2,val3';
        // Test ---
        map<String, Object> respMap = CSVUtility.headerListAndRowStringToRowMap(headers, rowString);
        // Assert ---
        map<String, Object> expectedMap = new map<String, Object>{
            'header1' => 'val1',
            'header2' => 'val2',
            'header3' => 'val3'
        };
        Assert.areEqual(expectedMap, respMap);
    }

    
    /// ----- CSVStringToMapList tests 

    @isTest 
    public static void testCSVStringToMapList(){
        /*
        #### Function:
            - CSVUtility.csvStringToMapList
        #### Inputs:
            -@csvString: string representation of a csv, first line is the header row,
                each subsequent line is a data row
        #### Expected Behaviour:
            - The first line is used as the headers, each following line is split on ','
                and paired with the headers to build one map per row, combined into a list
        #### Assertions:
            - The returned list has one map per data row
            - Each map pairs the headers with the values from its row
        */
        // Setup ---
        String csvString = 'header1,header2,header3\nkey1,key2,key3\nkey4,key5,key6\n';
        // Test ---
        list<Map<String, Object>> respList = CSVUtility.csvStringToMapList(csvString);
        // Assert ---
        list<Map<String, Object>> expectedList = new list<Map<String, Object>>{
            new map<String, Object>{'header1'=>'key1', 'header2'=>'key2', 'header3'=>'key3'},
            new map<String, Object>{'header1'=>'key4', 'header2'=>'key5', 'header3'=>'key6'}
        };
        Assert.areEqual(expectedList, respList);
    }



    // CSVContentDocumentIdToMapList tests --- 
    @isTest 
    public static void testCSVContentDocumentIdToMapList(){
        // Setup ----
        String fileString = 'header1,header2,header3\nkey1,key2,key3\nkey4,key5,key6\n';
        ContentVersion cv1 = new ContentVersion(Title = 'Test Document 1', PathOnClient = 'TestDoc1.CSV', VersionData = Blob.valueOf(fileString));
        insert(cv1);
        cv1 = [select id, contentDocumentId from ContentVersion where id=:cv1.id];
        /// Test ---- 
        list<Map<string, Object>> respList = CSVUtility.CSVContentDocumentIdToMapList(cv1.contentDocumentId);
        /// Assert ---- 
        list<Map<string, object>> expectedList = new list<Map<string, Object>>{
            new map<string, Object>{'header1'=>'key1', 'header2'=>'key2', 'header3'=>'key3'},
            new map<string, Object>{'header1'=>'key4', 'header2'=>'key5', 'header3'=>'key6'}
        };
        Assert.areEqual(expectedList, respList); 
    }


    // mapListToCSVFile tests ----
    @isTest 
    public static void testMapListToCSVFile(){
        /*
        #### Function:
            - CSVUtility.mapListToCSVFile
        #### Inputs:
            -@mapList: list of maps, each map representing a row
            -@resultFileName: filename including the .csv extension
        #### Expected Behaviour:
            - The map list is converted to a CSV string and saved as a ContentDocument
            - The .csv extension is stripped from the supplied filename to form the Title
            - The ContentVersion data holds the CSV representation of the map list
        #### Assertions:
            - A non-null ContentDocument Id is returned
            - The resulting ContentDocument Title has the .csv extension stripped
            - The stored file content matches the CSV string produced from the map list
        */
        // Setup ---
        List<Map<String, Object>> mapList = new List<Map<String, Object>>{
            new Map<String, Object>{'key1'=>1, 'key2'=>'2', 'key3'=>3},
            new Map<String, Object>{'key1'=>'a', 'key3'=>'c'},
            new Map<String, Object>{'key1'=>'test1', 'key2'=>'test2', 'key3'=>'test3'}
        };
        String expectedContent = CSVUtility.mapListToCSVString(mapList);
        // Test ---
        Test.startTest();
        Id respId = CSVUtility.mapListToCSVFile(mapList, 'resultName.csv');
        Test.stopTest();
        // Assert ---
        Assert.isNotNull(respId, 'A ContentDocument Id should be returned');
        ContentVersion cv = [SELECT Id, Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :respId LIMIT 1];
        Assert.areEqual('resultName', cv.Title, 'The .csv extension should be stripped from the Title');
        Assert.areEqual(expectedContent, cv.VersionData.toString(), 'The stored file content should match the CSV string built from the map list');
    }

    
    @isTest 
    public static void testSObjectListToCSVFile(){
        /*
        #### Function:
            - CSVUtility.sObjectListToCSVFile
        #### Inputs:
            -@sObjectList: list of sObjects, each representing a row
            -@resultFilename: filename including the .csv extension
        #### Expected Behaviour:
            - The sObject list is converted to a map list then to a CSV string and saved as a ContentDocument
            - The .csv extension is stripped from the supplied filename to form the Title
            - The ContentVersion data holds the CSV representation of the sObject list
        #### Assertions:
            - A non-null ContentDocument Id is returned
            - The resulting ContentDocument Title has the .csv extension stripped
            - The stored file content matches the CSV string produced from the equivalent map list
        */
        // Setup ---
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName='f1', LastName='l1', Email='123@mail.com'),
            new Contact(FirstName='f2', LastName='l2', Email='234@mail.com'),
            new Contact(FirstName='f3', LastName='l3')
        };
        String expectedContent = CSVUtility.mapListToCSVString(CSVUtility.sObjectListToMapList(contacts));
        // Test ---
        Test.startTest();
        Id respId = CSVUtility.sObjectListToCSVFile(contacts, 'contactsExport.csv');
        Test.stopTest();
        // Assert ---
        Assert.isNotNull(respId, 'A ContentDocument Id should be returned');
        ContentVersion cv = [SELECT Id, Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :respId LIMIT 1];
        Assert.areEqual('contactsExport', cv.Title, 'The .csv extension should be stripped from the Title');
        Assert.areEqual(expectedContent, cv.VersionData.toString(), 'The stored file content should match the CSV string built from the sObject-derived map list');
    }
}