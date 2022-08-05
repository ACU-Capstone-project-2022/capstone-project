<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, com.beanlib.*" %>
<%@ page errorPage="error.jsp" %>
<jsp:useBean id="login" class="com.beanlib.Authentication"></jsp:useBean>
<jsp:useBean id="workflow" class="com.beanlib.Workflow"></jsp:useBean>
<jsp:useBean id="util" class="com.beanlib.PRoAUtil"></jsp:useBean>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8" name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">

<title>Units with Allocated NLiCs and Peer Reviewers</title>
</head>

<body>
	<header>
		<h1>Peer Review of Assessment Workflow System</h1>
		<h2>Allocated NLiCs and Reviewers in Your Discipline</h2>
	</header>
	
	<div class="container">
		<%
		// If the user has not logged in, the unauthorised user needs to log in first
		if (session.getAttribute("login") == null || session.getAttribute("login") == " ") {
			response.sendRedirect("index.jsp");
			return;
		}

		// get arrays of nlics and reviewers for units to be reviewed from the input
		String[] nlics = request.getParameterValues("nlic");
		String[] reviewer1 = request.getParameterValues("reviewer1");
		String[] reviewer2 = request.getParameterValues("reviewer2");
		String[] reviewer3 = request.getParameterValues("reviewer3");
		
		
		// get the login user's discipline
		String disc = workflow.getDiscipline(session.getAttribute("login").toString()); // disc stands for discipline
		// query to retrieve all reviewed units under the discipline
		String sqlquery = "SELECT * FROM units WHERE 2boffered=1 AND 2breviewed=1 AND discipline = '" + disc + "' ORDER BY code ASC";

		// return true if the information of nlics and reviewers has been successfully written into the 'units' table
		if (workflow.setStakeholders(disc, sqlquery, nlics, reviewer1, reviewer2, reviewer3)) {
			// DH emails NLiCs
			String linkbase = request.getRequestURL().toString();
			String link = linkbase.substring(0, linkbase.indexOf("show_stakeholders.jsp"));
			
			String[] emailto = workflow.getEmailAddresses(sqlquery, "nlic");
			String emailsub = "PRoAWorkflow: Action Required from National Lecturer in Charge";
			String emailmsg = "Your discipline head has nominated your units for peer review. " + 
								"Please click <a href=\"" + link + "\" > this link </a> " + 
								"to Sign in as a National Lecturer in Charge " + 
								"and then Upload Original Assessments.";
			util.sendEmail(emailto, emailsub, emailmsg);
					
			String webmsg = "NLiCs have been informed to upload assessments!";
			out.print("<h3><font color=\"#3c1a50\">" + webmsg + "</font></h3>");
		} 
		else {
			out.print("<h3><font color=\"#cc0000\">Something is wrong!</font></h3>");
			out.print("<a href=\"dh.jsp\"><button type=\"submit\" id=\"backtohome\">" +
						"<i class=\"fa fa-home\"></i> Back to Home</button></a>");
			return;
		}
		%>

		<form method="post">
    <table class="table table-bordered table-striped">
      <thead>
        <tr>
          <th>Unit Code</th>
          <th>Unit Title</th>
          <th>NLiC's Email Address</th>
          <th>Reviewers' Email Addresses</th>
        </tr>
      </thead>
      <tbody>
      
      <%  DBResult dbr = workflow.getUnits(sqlquery);
          
          Connection conn = dbr.getCONN();
          PreparedStatement ps = dbr.getPS();
          ResultSet rs = dbr.getRS();
      
    	  while(rs.next()){
    		 String r1 =  rs.getString("reviewer1");
    		 String r2 =  rs.getString("reviewer2");
    		 String r3 =  rs.getString("reviewer3");
    		 
    		 String reviewers = r1;
    		 if (r2 != null) reviewers += "<br>" + r2;
    		 if (r3 != null) reviewers += "<br>" + r3;
    		  
    		 out.print("<tr>");

    		 out.print("<td>"+rs.getString("code")+"</td>");
     		 out.print("<td>"+rs.getString("name")+"</td>");
     		 out.print("<td>"+rs.getString("nlic")+"</td>");
     		 out.print("<td>"+ reviewers + "</td>");
     		 
     		 out.print("</tr>");
    		  
          } 
    	  
    	  rs.close(); 
    	  ps.close();
    	  conn.close();
     %>  
    </table>
    </form>
    <a href="dh.jsp"><button id="backtohome"><i class="fa fa-home"></i> Back to Home</button></a>
	</div>
</body>
</html>
