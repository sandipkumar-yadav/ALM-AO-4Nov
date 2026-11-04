public with sharing class FieldGenerationApexClass {
  
  @InvocableMethod(CapabilityType='PromptTemplateType://einstein_gpt__fieldCompletion')
  public static List<Response> getAccountsPrompt(List<Request> requests) {
	Request input = requests[0];
    List<Response> responses = new List<Response>();
    Response output = new Response();

    // FLS guard: strip fields the running user cannot read before accessing field values
    SObject[] accountList = new List<SObject>{ input.RelatedEntity };
    SObjectAccessDecision decision =
        Security.stripInaccessible(AccessType.READABLE, accountList);
    Account safeAccount = (Account) decision.getRecords()[0];

    String accountName  = safeAccount.Name  != null ? safeAccount.Name  : '';
    String accountPhone = safeAccount.Phone != null ? safeAccount.Phone : '';

    output.Prompt = 'Account Name= ' + accountName + ' having Phone number as : ' + accountPhone;
    responses.add(output);
    return responses;
      
  }
    
    public class Request {
	@InvocableVariable
    	public Account RelatedEntity;
	}
      
    public class Response {
    @InvocableVariable(required=true)
    	public String Prompt;
	}
}
