public class CAIAUserDataJSON{
	public string username;
	public String userInfoJSONString;	
	public String siteLoginUrl;
	public String provider;	//Open ID Connect
	public String locale;
	public String link;
	public string lastName;
	public String idTokenJSONString;	//{"sub":"**treasury.gov","aud":"29b93473-8cd4-4c12-b495-30ad56c8311b","acr":"http://idmanagement.gov/ns/assurance/ial/2/aal/2","s_hash":"5j7jLLUzmMMu_zCqR0w9LQ","auth_time":1757303525,"iss":"https://caia.treasury.gov","pi.sri":"JnJtI2gIJjQ6r4QPM91Ro1yrprk.cGti","exp":1757303828,"iat":1757303528,"jti":"NGbaLraoqQKELAsplzNWBH","sid":"JnJtI2gIJjQ6r4QPM91Ro1yrprk.cGti"}
	public String idToken;	//eyJhbGciOiJSUzI1NiIsImtpZCI6ImNmNkV5RjZDREtSZU1iN2NNMHU5allMQ29kVV9SUzI1NiJ9.eyJzdWIiOiJyYWh1bC5iYWRhbEB0cmVhc3VyeS5nb3YiLCJhdWQiOiIyOWI5MzQ3My04Y2Q0LTRjMTItYjQ5NS0zMGFkNTZjODMxMWIiLCJqdGkiOiJOR2JhTHJhb3FRS0VMQXNwbHpOV0JIIiwiaXNzIjoiaHR0cHM6Ly9jYWlhLnRyZWFzdXJ5LmdvdiIsImlhdCI6MTc1NzMwMzUyOCwiZXhwIjoxNzU3MzAzODI4LCJhdXRoX3RpbWUiOjE3NTczMDM1MjUsImFjciI6Imh0dHA6Ly9pZG1hbmFnZW1lbnQuZ292L25zL2Fzc3VyYW5jZS9pYWwvMi9hYWwvMiIsInBpLnNyaSI6IkpuSnRJMmdJSmpRNnI0UVBNOTFSbzF5cnByay5jR3RpIiwic2lkIjoiSm5KdEkyZ0lKalE2cjRRUE05MVJvMXlycHJrLmNHdGkiLCJzX2hhc2giOiI1ajdqTExVem1NTXVfekNxUjB3OUxRIn0.BYdoRm8SPW_Viy4V78Q-oM3LpoCKG22qvNXvtA01sbP2bV0SdmX-CmS3TDk6uursOrLuT9Ru7nbAYiWZAEWFErjlwuYvXfRk64MwXDxBwvqhd9_uiKO6bAc9ASRiUqvV9IRLnP2_477OViWpo5bnTs-oD133YM7ULXzyF8OuF3MhYHk6TSMNLcCMERGjyQGqgxLXQ-NW8R4NvGWHJ6bZ868pQbYJDhTuOi8vhOVtBLSpRXEEJvzjXCFpCHNob0t4jmwPm_Bz47mwkjFl8SOooWb_xQyBjgdnMhkJGuIXJXdWMVFMUHjDoJ710xuDgGXgU9YtcswlpddLXRG7GxUIVg
	public String identifier;	//**treasury.gov
	public String fullName;
	public String firstName;
	public String email;	//**treasury.gov
	public cls_attributeMap attributeMap;
	
	public class cls_attributeMap {
		public String email;	//**treasury.gov
		public String sub;	//**treasury.gov
        public string uuid;
		public String emplid;	//123456
	}
	public static CAIAUserDataJSON parse(String json){
		return (CAIAUserDataJSON) System.JSON.deserialize(json, CAIAUserDataJSON.class);
	}
	
}