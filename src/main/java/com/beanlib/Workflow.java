package com.beanlib;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.sql.Blob;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Properties;

import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

import org.apache.commons.io.FilenameUtils;

import org.apache.commons.lang3.RandomStringUtils;
import org.mindrot.jbcrypt.BCrypt;

//the class for handling all workflow activities
public class Workflow {
	// all assessment related information in the units table
	final String[] at_label = {"at1", "at2", "at3"};
 	final String[] at_status = {"at1_status", "at2_status", "at3_status"};
 	final String[] at_feedback = {"at1_feedback", "at2_feedback", "at3_feedback"};
 	final String[] at_type = {"at1_type", "at2_type", "at3_type"};
 	final String[] reviewer1_at = {"reviewer1_at1", "reviewer1_at2", "reviewer1_at3"};
	final String[] reviewer2_at = {"reviewer2_at1", "reviewer2_at2", "reviewer2_at3"};
	final String[] reviewer3_at = {"reviewer3_at1", "reviewer3_at2", "reviewer3_at3"};		
	final String[] reviewer_x = {"reviewer1", "reviewer2", "reviewer3"};

	/* set the offered units to be reviewed in the database and 
	 * return discipline head email addresses so that they will be informed to allocate stakeholders
	 * Sprint 2 is to complete this method 
	 * Hints: 
	 *   1. Declare a HashSet object to store unique discipline head email addresses
	 *   2. use the same sql query in norminate_units.jsp to retrieve all units with 
	 *   	options ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE so that you can update the table
	 *   3. Use a while (rs.next()) loop to check whether the current row number (using variable row) is in the offered array 
	 *   	(using index i). If yes, the '2boffered' column of the 'units' table is set to 1 and advance index i. 
	 *   4. Further check whether the row is also in the reviewed array (using index j). If also yes, 
	 *   	the '2breviewed' column of the 'units' table is set to 1 and advance index j. For the unit to be reviewed, 
	 *   	retrieve its discipline head email addresses using method getEmailAddresses(sqlquery, "") and add them to the HashSet.
	 *   	The sqlquery should have conditions specifying which discipline (discipline=??) and the dh role (roles LIKE '%dh%'). 
	 *   	Finally update the entire row of the table.
	 *   5. Convert the HashSet into an array and return it.
	 * 
	 */
	
	private Boolean isRowInArray(String[] array, int rowIndex) {
		for (int i = 0; i < array.length; i++) {
			if (Integer.parseInt(array[i]) == rowIndex)
					return true;
		}
		return false;
	}
	
	public String[] setReviewedUnits(String[] offered, String[] reviewed) {
		// using HashSet to store unique discipline head email 
		// addresses (potentially more than one person)
		Set<String> dhs = new HashSet<String>();
		Connection conn;
		try {
			conn = DriverManager.getConnection(Configuration.dbConnectionURL);
			PreparedStatement ps = conn.prepareStatement("SELECT * FROM units ORDER BY discipline ASC, code ASC", ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE); 
			ResultSet rs = ps.executeQuery();

			int rowIndex = 0;

			while (rs.next()) {
				if (isRowInArray(offered, rowIndex)) {
					rs.updateInt("2boffered", 1);
			        if (isRowInArray(reviewed, rowIndex)) {
						rs.updateInt("2breviewed", 1);
						String sqlQuery = "SELECT * FROM login WHERE discipline='" + rs.getString("discipline") + "' AND roles LIKE '%dh%'";
						String[] emailAdresses = getEmailAddresses(sqlQuery, "");
						for (int i = 0; i < emailAdresses.length; i++) {
							System.out.println(emailAdresses[i]);
							dhs.add(emailAdresses[i]);
						}
					}
			        rs.updateRow();
				}
				rowIndex++;
			}
		} catch (SQLException e) {
			// TODO Auto-generated catch block 
			e.printStackTrace();
		}

		// convert HashSet to an array
		String[] simpleArray = new String[dhs.size()];
		dhs.toArray(simpleArray);
		
		return simpleArray;
		
	}
	
	// Store NLiC and reviewer for each unit to be reviewed 
	// Called by DH
	public Boolean setStakeholders(String disc, String sqlquery, String[] nlics, String[] reviewer1, String[] reviewer2, String[] reviewer3) {
		// whether the information is stored successfully
		Boolean updateSuccess = false;

		try {
			// load and register JDBC driver for MySQL
			Class.forName("com.mysql.cj.jdbc.Driver");
			Connection conn = DriverManager.getConnection(Configuration.dbConnectionURL);
			PreparedStatement ps=conn.prepareStatement(sqlquery, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE); 

			ResultSet rs = ps.executeQuery();
			// write each element in the arrays to the corresponding rows returned by the query
			int i = 0;
			while (rs.next() && i < reviewer1.length) {
				rs.updateString("nlic", nlics[i]);
				rs.updateString("reviewer1", reviewer1[i]);

				if (reviewer2[i] != null && reviewer2[i] != "") 
					rs.updateString("reviewer2", reviewer2[i]);

				if (reviewer3[i] != null && reviewer3[i] != "") 
					rs.updateString("reviewer3", reviewer3[i]);

				rs.updateRow();
				i++;
				updateSuccess = true;
			}

			rs.close();
			ps.close();
			conn.close();

		} catch(Exception e) {
			e.printStackTrace();
		}

		return updateSuccess;

	}

	//retrieve relevant units using sqlquery
	public DBResult getUnits(String sqlquery) {
		DBResult dbr = null;
		
		try {
			// load and register JDBC driver for MySQL
			Class.forName("com.mysql.cj.jdbc.Driver");
			Connection conn = DriverManager.getConnection(Configuration.dbConnectionURL);
			PreparedStatement ps=conn.prepareStatement(sqlquery); 
			ResultSet rs = ps.executeQuery();
			
			dbr = new DBResult(conn, ps, rs);
						
		} catch(Exception e) {
	         //Handle errors for Class.forName
	         e.printStackTrace();
		}
		return dbr;
		
	}
	
	// return a user's discipline based on its login email
	public String getDiscipline(String email) {
		String discipline = "";
		
		try {
			// load and register JDBC driver for MySQL
			Class.forName("com.mysql.cj.jdbc.Driver");
			Connection conn = DriverManager.getConnection(Configuration.dbConnectionURL);
			PreparedStatement ps=conn.prepareStatement("select * from login where email=?"); 
			ps.setString(1, email);
			
			ResultSet rs = ps.executeQuery();
			
			if (rs.next()) {
				discipline = rs.getString("discipline");
			}
						
		} catch(Exception e) {
	         //Handle errors for Class.forName
	         e.printStackTrace();
		}
		
		return discipline;
		
	}
	
	// return the email addresses depending on sqlquery and role
	public String[] getEmailAddresses(String sqlquery, String role) {
			// using HashSet to store unique email 
			// addresses (potentially more than one person)			
			List<String> emailaddrs = new ArrayList<String>();
			
			try {
				// load and register JDBC driver for MySQL
				Class.forName("com.mysql.cj.jdbc.Driver");
				Connection conn = DriverManager.getConnection(Configuration.dbConnectionURL);
				PreparedStatement ps=conn.prepareStatement(sqlquery); 
				ResultSet rs = ps.executeQuery();
				
				while (rs.next()) {
					// if role is not specified, all email addresses returned by sqlquery are added
					if (role.equals("")) {
						emailaddrs.add(rs.getString("email"));
					// add email addresses of this specified role 
					} else {
						// value of the field may be null
						String addr = rs.getString(role);
						if (addr != null) emailaddrs.add(addr);
					}
					
				}
							
			} catch(Exception e) {
		         //Handle errors for Class.forName
		         e.printStackTrace();
			}
			// convert HashSet to an array
			String[] simpleArray = new String[emailaddrs.size()];			
			emailaddrs.toArray(simpleArray);
			
			return simpleArray;
			
	}
	
	// set assessment statuses
	/* Each assessment may be in one of the following status after upload:
	 1. uploaded: original assessment uploaded by NLiC
	 2. lt_returned: returned to NLiC via L&T screening due to compliance issues before review
	 3. dh_returned: returned to NLiC via DH checking due to issues after review and revision
	 4. ready: ready for review marked by L&T
	 5. reviewed: reviewed by all reviewers (reviewed) or by some of them (reviewer1/reviewer2/reviewer3)
	 6. revised: revised by NLiC by addressing review comments
	 7. approved: approved by DH for publishing
    */
	public void setAssessmentStatus(String code, List<String> columns, List<String> values) {		
		try {
			// load and register JDBC driver for MySQL
			Class.forName("com.mysql.cj.jdbc.Driver");
			Connection conn = DriverManager.getConnection(Configuration.dbConnectionURL);
			String sqlquery = "SELECT * from units where code= '" + code + "'";
			PreparedStatement ps=conn.prepareStatement(sqlquery, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE); 
			ResultSet rs = ps.executeQuery();
			
			if (rs.next()) {
				for (int i=0; i<columns.size(); i++) {
					rs.updateString(columns.get(i), values.get(i));
				}  	
	 		    rs.updateRow();
			}
			
			rs.close();
			ps.close();
			conn.close();
						
		} catch(Exception e) {
	         //Handle errors for Class.forName
	         e.printStackTrace();
		}
	}
	
	/* store uploaded/revised assessments into database and set appropriate assessment statuses
	 * Sprints 3 and 4 are to complete this method.
	 * Sprint 3 needs to: (1) set each assessment file type, (2) set each assessment status, 
	 * 		(3) upload each assessment by nlic and upload each reviewed assessment by a pr
	 * Hints:
	 * 1. execute sqlquery with options ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE so that you can update rows.
	 * 2. for each row, process each assessment (using a for loop with variable i)
	 * 		- get the file from multipart: javax.servlet.http.Part file = request.getPart(at_no[i]) 
	 * 			(at_no[i] is the same as defined in upload_assessment.jsp)
	 * 		- if file is not null, get its inputstream using getInputStream() method and get its file name 
	 * 			using the provided getFileName(final javax.servlet.http.Part part) method
	 * 		- save the file extension as the assessment type
	 * 		- if the file's inputstream has something to read (available() >0) and the assessment status is not null 
	 * 			(based on the hidden at_no[i] variable from upload_assessment.jsp), set the assessment status in the database
	 * 			and save the inputstream into the database as an assessment (at_label[i]) uploaded by nlic 
	 * 			or as a reviewed assessment (reviewer1_at[i], reviewer2_at[i], or reviewer3_at[i]) uploaded by a pr
	 * 		- update the row and process the next row.
	 * 
	 * Sprint 4 needs to: (1) set each assessment status from "reviewerX" to "reviewed" after it
	 * 		has been reviewed by all assigned reviewers, (2) return an appropriate "uploadState" 
	 * Hints: for (1), if an assessment status starts with "reviewer", you need to cross check "reviewerX" and "reviewerX_at[i]". 
	 * 			The logic is (getString("reviewerX")==null || getBlob(reviewerX_at[i]) != null). If reviewerX does not exist (first one is true),
	 * 			the second one will not be evaluated. Otherwise, the second one must be true (i.e., reviewed assessment uploaded). When all
	 * 			expected reviewers have uploaded their reviewed assessments, the status is changed to "reviewed".
	 * 		  for (2), use the "states" variable to record relevant statuses and then use string searching to determine the correct "uploadState"
	 */
	
	//-1: upload unsuccessful, 0: only uploaded by nlic, 1: only revised by nlic, 
	//2: mix of uploaded and revised by nlic, 3: reviewed by pr
	// If it contains "reviewed" (reviewed by all reviewers) or "reviewer" (not reviewed by all reviewers),
	// uploadState should return 3. If it contains both "uploaded" and "revised", it should return 2.
	// If it contains "revised", it should return 1. If it contains "uploaded", it should return 0.
	public int uploadAssessments(HttpServletRequest request, String sqlquery) {				
		int uploadState = -1;
		String states = "";

		
		Connection conn;
		try {
			conn = DriverManager.getConnection(Configuration.dbConnectionURL);
			PreparedStatement ps = conn.prepareStatement(sqlquery, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE); 
			ResultSet rs = ps.executeQuery();
			
			System.out.println(request);
			for (int row = 0; rs.next(); row++) {
				String[] at_no = {Integer.toString(row) + "_1", Integer.toString(row) + "_2", Integer.toString(row) + "_3"};
				
				for (int i = 0; i < 3; i++) {
					if (request.getPart(at_no[i]) == null) {						
						continue;
					}
					javax.servlet.http.Part file = request.getPart(at_no[i]);
					String filename = this.getFileName(file);

					if (filename.length() > 0) {
						InputStream inputstream = file.getInputStream();
						System.out.println("filename: ["+ filename + "]");
						
						if (inputstream.available() > 0 && rs.getString("at" + Integer.toString(i + 1) + "_status") != "null") {
							
							// set assessment file type
							String filetype = FilenameUtils.getExtension(filename);
							System.out.println("filetype: ["+ filetype + "]");
							rs.updateString(at_type[i], filetype);
							
							
							
							// set assessment status							
							String status= request.getParameter(at_no[i]);
							if (isReviewedByAllReviewers(rs, i, status) && !status.equals("revised")) {
								status = "reviewed";
							}
							states = status;
							System.out.println("status: ["+ status + "]");
							rs.updateString(at_status[i], status);
							
							// store file in db
							InputStream fileData=inputstream;
							System.out.println("fileData: ["+ fileData + "]");
							
							if (request.getParameter(at_no[i]).equals("uploaded") || request.getParameter(at_no[i]).equals("revised")) {
								System.out.println("Uploaded by nlic");
								rs.updateBlob(at_label[i], fileData);
							} else {
								String col_name = getReviewerAt(request.getParameter(at_no[i]), i);
								rs.updateBlob(col_name, fileData);
								System.out.println("Uploaded by PR");
							}
							
							
							
							rs.updateRow();							
						}						
					} else {
						System.out.println("file null");
					}
				}
				uploadState =  0;
			}
			uploadState =  0;
		} catch (Exception e) {
			System.out.println(e);
			uploadState =  -1;
		}
		if (states.equals("reviewed") || states.contains("reviewer")) {
			uploadState = 3;
		}
		if (states.contains("uploaded") && states.contains("revised")) {
			uploadState = 2;
		}
		if (states.equals("revised")) {
			uploadState = 1;
		}
		if (states.equals("uploaded")) {
			uploadState = 0;
		}
		System.out.println("uploadState = " + uploadState);
		return uploadState;
		
	}
	
	private Boolean isReviewedByAllReviewers(ResultSet rs, int i, String status) {
		try {			
			for (int r = 0; r < 3; r++) {
				System.out.println("Here");
				if (rs.getString(reviewer_x[r]) != null && rs.getBlob(getReviewerAt(reviewer_x[r], i)) == null && !status.equals(reviewer_x[r])) {
					System.out.println(reviewer_x[r]);
					System.out.println(status);
					System.out.println("returning false");
					return false;
				}
			}
			return true;
		} catch (Exception e) {
			System.out.println(e);
			return false;
		}
	}

	private String getReviewerAt(String status, int i) {
		switch(status) {
		case "reviewer1":
			return reviewer1_at[i];
		case "reviewer2":
			return reviewer2_at[i];
		case "reviewer3":
			return reviewer3_at[i];
		}
		return "";
	}
	// download assessments from database to the web server and make it accessible via urls
	/* Sprint 5 is to complete this method
	 * Hints:
	 * 1. execute sqlquery to retrieve relevant units
	 * 2. for each row, process each assessment (using a for loop with variable i)
	 * 		- reconstruct the full file name at_id+type (at_id as in download_assessments.jsp)
	 * 		- download the assessment to file by using the method downloadToFile(HttpServletRequest request, String filename, Blob b)
	 * 		- download all reviewed assessments using the same method
	 */
	public void downloadAssessment(HttpServletRequest request, String sqlquery) {
        Connection conn;
        try {
            conn = DriverManager.getConnection(Configuration.dbConnectionURL);
            PreparedStatement ps = conn.prepareStatement("SELECT * FROM units ORDER BY discipline ASC, code ASC", ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE); 
            ResultSet rs = ps.executeQuery();

            System.out.println(sqlquery);

            for (int row = 0; rs.next(); row++) {
                String code = rs.getString("code");

                for (int i = 0; i < 3; i++) {
                	Blob label = rs.getBlob(at_label[i]);
                	if (label == null) {                		
                		continue;
                	}
                    String attype = rs.getString(at_type[i]);
                    String FileName = code + "_" + at_label[i] + attype;
                    System.out.println(FileName);
                    try {
                        downloadToFile(request, FileName, label);
                    } catch (Exception e) { 
                        e.printStackTrace();
                    }

                }

            }

        } catch (SQLException e) {
            // TODO Auto-generated catch block 
            e.printStackTrace();
        }

    }
	
	// save blob (b) from database to a file (filename)
	private void downloadToFile(HttpServletRequest request, String filename, Blob b)
			throws SQLException, FileNotFoundException, IOException {
		// convert blob into a byte array
		byte[] bdata = b.getBytes(1, (int) b.length());
		// location of the file
		final File f = new File(request.getServletContext().getRealPath(".") + "/" + filename);
		// write the byte array to the file
		OutputStream output = new FileOutputStream(f);				     	
		output.write(bdata); 
		output.flush();
		output.close();
	}
	
	// Return the name of the uploaded file from a multipart body in a form
	// example:
	// Content-Disposition: form-data; name="fieldName"
	// Content-Disposition: form-data; name="fieldName"; filename="filename.jpg"
	private String getFileName(final javax.servlet.http.Part part) {
	    for (String content : part.getHeader("content-disposition").split(";")) {
	        if (content.trim().startsWith("filename")) {
	            return content.substring(content.indexOf('=') + 1).trim().replace("\"", "");
	        }
	    }
	    return null;
	}
	
	// This method checks which reviewer the login user is
	public String whichReviewer(HttpServletRequest request, HttpSession session, ResultSet resultSet) throws Exception {
		String reviewer = null;

		String role = request.getParameter("role");
		String user = session.getAttribute("login").toString();

		if (resultSet != null && role.equals("pr")) {
			if (resultSet.getString("reviewer1") != null && resultSet.getString("reviewer1").equals(user)) {
				reviewer = "reviewer1";
			}
			else if (resultSet.getString("reviewer2") != null && resultSet.getString("reviewer2").equals(user)) {
				reviewer = "reviewer2";
			}
			else if (resultSet.getString("reviewer3") != null && resultSet.getString("reviewer3").equals(user)) {
				reviewer = "reviewer3";
			}
		}
		return reviewer;
		}
}