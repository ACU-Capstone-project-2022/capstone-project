<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, org.apache.commons.lang3.ArrayUtils" %>
<%@ page import="com.beanlib.Authentication, com.beanlib.DBResult, com.beanlib.Workflow" %>
<%@ page errorPage="error.jsp" %>
<jsp:useBean id="login" class="com.beanlib.Authentication"></jsp:useBean>
<jsp:useBean id="workflow" class="com.beanlib.Workflow"></jsp:useBean>
<jsp:useBean id="util" class="com.beanlib.PRoAUtil"></jsp:useBean>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" name="viewport" content="width=device-width, initial-scale=1">

<title>Process Assessments</title>
</head>

<body>
	<%
	// If the user has not logged in, the unauthorised user needs to log in first
	if (session.getAttribute("login") == null || session.getAttribute("login") == " ") {
		response.sendRedirect("index.jsp");
		return;
	}

	String code = request.getParameter("code"); // the code column in the units table for this request
	String role = request.getParameter("role"); // the role column in the login table for this request
	String status = "";
	String sqlquery = "SELECT * FROM units WHERE 2boffered=1 AND 2breviewed=1 AND code=\'" + code + "\'";
	// Extract the URL of the request
	String linkbase = request.getRequestURL().toString();
	String link = linkbase.substring(0, linkbase.indexOf("process_assessments.jsp"));

	// this list saves columns in the 'units' table requiring updating
	List<String> columns = new ArrayList<String>();
	 
	// this list saves values of the columns to be updated
	List<String> values = new ArrayList<String>();
	// potential columns requiring updating
	String[] at_status = {"at1_status", "at2_status", "at3_status"};
	String[] at_feedback = {"at1_feedback", "at2_feedback", "at3_feedback"};

	// Fill in the two lists
	for (int i = 0; i < 3; i++) {
		// if the choice is TO RETURN TO NLiC with feedback
		if (request.getParameter("choice_" + i) != null && request.getParameter("choice_" + i).equals("return")) {
			columns.add(at_status[i]); // the add method can be used for the columns variable since it is a List
			columns.add(at_feedback[i]);
			// check and return by lt
			if (role.equals("lt")) {
				status = "lt_returned";
				// LT emails NLiC
				String[] emailto = workflow.getEmailAddresses(sqlquery, "nlic");
				String emailsub = "PRoAWorkflow: Action Required from National Lecturer in Charge";
				String emailmsg = code + " assessments have been checked by Learning & Teaching Officer. " + 
									"Please click <a href=\"" + link + "\"> this link </a> to Sign in as a National Lecturer in Charge " + 
									"and then View Checked/Reviewed Assessments";
				
				util.sendEmail(emailto, emailsub, emailmsg);
			}
			// check and return by dh
			else if (role.equals("dh")) {
				status = "dh_returned";
				// DH emails NLiC
				String[] emailto = workflow.getEmailAddresses(sqlquery, "nlic");
				String emailsub = "PRoAWorkflow: Action Required from National Lecturer in Charge";
				String emailmsg = code + " assessments have been checked by Discipline Head. " + 
									"Please click <a href=\"" + link + "\">" + "this link </a> to Sign in as a National Lecturer in Charge " + 
									"and then View Checked/Reviewed Assessments";
									
				util.sendEmail(emailto, emailsub, emailmsg);
			}

			values.add(status);
			values.add(request.getParameter("feedback_" + i));
		}
		// if the choice is TO PASS THE CHECK
		else if (request.getParameter("choice_" + i) != null && request.getParameter("choice_" + i).equals("pass")) {
			columns.add(at_status[i]);
			// lt checks and marks assessment ready for review
			if (role.equals("lt")) {
				status = "ready";
				
				// LT emails PRs
				String[] emailto1 = workflow.getEmailAddresses(sqlquery, "reviewer1");
				String[] emailto2 = workflow.getEmailAddresses(sqlquery, "reviewer2");
				String[] emailto3 = workflow.getEmailAddresses(sqlquery, "reviewer3");
				String[] emailto = ArrayUtils.addAll(ArrayUtils.addAll(emailto1, emailto2), emailto3);
				
				String emailsub = "PRoAWorkflow: Action Required from Peer Reviewer";
				String emailmsg = code + " assessments are ready for your review. Please click <a href=\"" + link + "\"> this link </a> " + 
									" to Sign in as a Peer Reviewer and then Download Submitted Assessments";
						
				util.sendEmail(emailto, emailsub, emailmsg);
			}
			// dh checks and approves assessment
			else if (role.equals("dh")) {
				status = "approved";
				
				// DH emails NLiC
				String[] emailto = workflow.getEmailAddresses(sqlquery, "nlic");
				String emailsub = "PRoAWorkflow: Action Required from National Lecturer in Charge";
				String emailmsg = code + " assessments are approved by Discipline Head. Please click <a href=\"" + link	+ "\"> this link </a> " +
									" to Sign in as a National Lecturer in Charge and then View Approved Assessments";
									
				util.sendEmail(emailto, emailsub, emailmsg);
			}

			values.add(status);
		}
	}
	
	// update the 'units' table with the information saved in the lists
	workflow.setAssessmentStatus(code, columns, values);
	// process the next unit if any
	response.sendRedirect("check_assessments.jsp?role=" + role);
	%>
</body>
</html>