public with sharing class FlexApexClass {
  @InvocableMethod()
  public static List<Response> getCaseContactPrompt(List<Request> requests) {
    Request input = requests[0];
    List<Response> responses = new List<Response>();
    Response output = new Response();

    // FLS guard: strip fields the running user cannot read before accessing field values
    SObject[] accountList = new List<SObject>{ input.My_Account };
    SObject[] caseList    = new List<SObject>{ input.My_Case };

    SObjectAccessDecision accountDecision =
        Security.stripInaccessible(AccessType.READABLE, accountList);
    SObjectAccessDecision caseDecision =
        Security.stripInaccessible(AccessType.READABLE, caseList);

    Account safeAccount = (Account) accountDecision.getRecords()[0];
    Case    safeCase    = (Case)    caseDecision.getRecords()[0];

    String accountName  = safeAccount.Name    != null ? safeAccount.Name    : '';
    String caseSubject  = safeCase.Subject     != null ? safeCase.Subject    : '';

    // update below prompt as per the template inputs
    output.Prompt = 'create an new email for account=' + accountName + ' case=' + caseSubject;
    responses.add(output);
    return responses;
  }
  
  // All inputs will be from the template into the apex class
  public class Request {
  // update below input entity and apiName as per Flex template. 
      @InvocableVariable
      public Account My_Account;
      @InvocableVariable
      public Case My_Case;
  }
  
  public class Response {
    @InvocableVariable(required=true)
    public String Prompt;
  }
}
