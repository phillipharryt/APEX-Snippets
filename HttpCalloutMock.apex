global class statusCodeMockResponse implements HttpCalloutMock {
    // An example mock class, so you can inspect attributes of the callout
    Integer statusCode;
    String jsonResponse;
    public String postedData;
    public String endpointUsed;

    public statusCodeMockResponse(Integer code, String json) {
      jsonResponse = json;
      statusCode = code;
    }

    global HttpResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(statusCode);
      res.setBody(jsonResponse);
      postedData = req.getBody();
      endpointUSed = req.getEndpoint();
      return res;
    }
}