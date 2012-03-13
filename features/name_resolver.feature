Feature: Name resolver for reconciling names from external list to internal GNI databases
  In order to be able to find how names in user's list relate to names in a GNI data source
  A user should be able to send names by GET, POST, uploading a file and get response back
  And receive back data about names found in a data source according to user's list

  Scenario: Using GET API call to resolve several names
    Given names "Leiothrix argentauris (Hodgson, 1838)|Treron|Larus occidentalis wymani|Plantago major L."
    And data source identifiers "1|2"
    And format "xml"
    When I GET name_resolvers with the parameters
    Then new resolver instance is created
    And I get an anticipated response with resolved names

  Scenario: Using POST API call to resolve names
    Given names "Leiothrix argentauris (Hodgson, 1838)|Treron|Larus occidentalis wymani|Plantago major L."
    And data source identifiers "1|2"
    And format "xml"
    When I GET name_resolvers with the parameters
    Then new resolver instance is created
    And I get an anticipated response with resolved names



