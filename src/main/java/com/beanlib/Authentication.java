package com.beanlib;

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

import org.apache.commons.lang3.RandomStringUtils;
import org.mindrot.jbcrypt.BCrypt;

/* This Bean class contains methods for registering a new user, 
 * validating user login, updating and removing login, changing password, 
 * and returning user info
 */
public class Authentication {
	// Attributes
	String firstname;
	String lastname;
	String discipline;
	String email;
	String password;
	String passwordNew;
	String loginrole;
	String roles;
			
	// public accessors
	public String getFirstname() { return firstname;}
	public String getLastname() { return lastname;}
	public String getDiscipline() { return discipline;}
	public String getEmail() { return email;}
	public String getPassword() {return password;}
	public String getPasswordNew() {return passwordNew;}
	public String getLoginrole() {return loginrole;}
	public String getRoles() {return roles;}
	
	public void setFirstname (String first) { firstname = first;}
	public void setLastname (String last) { lastname = last;}
	public void setDiscipline (String disc) { discipline = disc;}
	public void setEmail (String em) { email = em; }
	public void setPassword (String pass) {	password = pass;}
	public void setPasswordNew (String passnew) {	passwordNew = passnew;}
	public void setLoginrole (String tr) { loginrole = tr;}
	public void setRoles (String ar) { roles = ar;}
	
	//check whether login information is valid
	public int validateLogin() {
		int loginCode = -2; // -2: login failed, -1: permission denied, 0: account not activated, 1: login succeeded 
		
		try {
			// load and register JDBC driver for MySQL
			Class.forName("com.mysql.cj.jdbc.Driver");
			// establish a connection to the database
			Connection conn = DriverManager.getConnection(Configuration.dbConnectionURL);
			// prepare a SQl statement
			PreparedStatement ps=conn.prepareStatement("select * from login where email=?"); 
			// provide parameter values
			ps.setString(1, email);
			// execute sql query
			ResultSet rs = ps.executeQuery();

			if (rs.next()) {
				// database stores encrypted password
				String hashedpw = rs.getString("password");

				// password matches and account activated
				if (BCrypt.checkpw(password, hashedpw) && rs.getInt("activated") == 1 && rs.getString("roles").indexOf(loginrole) != -1) {
					loginCode = 1;	
				// selected role not permitted
				} else if (BCrypt.checkpw(password, hashedpw) && rs.getInt("activated") == 1) {
					loginCode = -1;	
				// account not activated
				} else if (BCrypt.checkpw(password, hashedpw)) {
					loginCode = 0;	
				}
			}

			// close resultset, statement and connection
			rs.close();
			ps.close();
			conn.close();
						
		 } catch(Exception e) {
	         //Handle errors for Class.forName
	         e.printStackTrace();
		 }
		
		return loginCode;
		
	}
	
	// register a new user
	/* Sprint 1 needs to complete this method
	 * 
	 * Hints:
	 * 1. call InitDB() to create database and tables 
	 * 2. search the entered email address from the login table, if it exists, regcode = 0
	 * 3. if it does not exist, insert the account information (firstname, lastname, email, password) into login table, and regcode = 1
	 * 4. before that, you need to encrypt the password using the following code and store hashedpw into the table.
	 * 		String hashedpw = BCrypt.hashpw(password, BCrypt.gensalt(12));
	 */
	public int registerLogin() {
		int regcode = -1; //-1: error, 0: email exists, 1: successful

		// ************************************************** //
		//System.out.println("Check if user exists");
		// Bugs: Longer then 1 word user names, malicious strings,special characters
		try {
			// create database and tables
			Connection conn = InitDB();
			// prepare a SQl statement
			PreparedStatement ps1=conn.prepareStatement("Select * from proadb.login where email = ?"); 
			ps1.setString(1, email);

			// execute sql query		
			
			ResultSet rs = ps1.executeQuery();
			System.out.println(rs);		
			System.out.println(ps1);
			
			
			if (rs.next()) {
				regcode = 0;
			} else {
				regcode = 1;	
			} 
			
			// statement and connection
			ps1.close();
			
			try {
				
				//check if user Exists or Not. Check if regcode = 0
				System.out.println("Check regcode");
				System.out.println(regcode);
				if (regcode == 1){
						
					// prepare a SQl statement
					//PreparedStatement ps=conn.prepareStatement("INSERT INTO proadb.login (firstname, lastname, discipline, email, password ) VALUES ('harry', 'shaw', 'Test', 'harry@gmail.com', 'harry123');");
					PreparedStatement pst=conn.prepareStatement("INSERT INTO proadb.login (firstname, lastname, discipline, email, password ) VALUES ( ?, ?, ?, ?, ?);");
					
					pst.setString(1, firstname);
					pst.setString(2, lastname);
					pst.setString(3, discipline);
					pst.setString(4, email);
					
					String hashedpw = BCrypt.hashpw(password, BCrypt.gensalt(12));
					pst.setString(5, hashedpw);
		
					
					// execute sql query
					pst.execute();
		
					// statement and connection
					pst.close();
					conn.close();
				} else {
					regcode = -1;
					System.out.println("User Already Exists");
				}

			} catch(Exception e) {
				//Handle errors for Class.forName
				e.printStackTrace();
				regcode = -1;
			}
			
			
			
			conn.close();

		} catch(Exception e) {
			//Handle errors for Class.forName
			e.printStackTrace();
			regcode = -1;
		}
		
		// ************************************************** //
		//System.out.println("Create User");
		
		return regcode;
		
	}
	
	// Create database and tables
	// return a connection to database for further use
	private Connection InitDB() {
		Connection conn = null;

		try {
			// load and register JDBC driver for MySQL
			Class.forName("com.mysql.cj.jdbc.Driver");
			//establish connection to mysql server
			conn = DriverManager.getConnection(Configuration.connectionURL);
			//create aoldb database
			String createdb = "CREATE DATABASE IF NOT EXISTS proadb";
			PreparedStatement ps = conn.prepareStatement(createdb);
			ps.execute();
			
			String createtable = "CREATE TABLE IF NOT EXISTS proadb.login ("
					+ "firstname varchar(10) NOT NULL,"
					+ "lastname varchar(12) NOT NULL,"
					+ "discipline varchar(4) NOT NULL, "
					+ "email varchar(40) NOT NULL,"
					+ "password varchar(200) NOT NULL, "
					+ "roles varchar(45) NOT NULL, "
					+ "activated INT NULL, "
					+ "acticode varchar(10) NULL, "
					+ "PRIMARY KEY (email)) "
					+ " ENGINE = InnoDB DEFAULT CHARACTER SET = utf8";
				
			ps = conn.prepareStatement(createtable);
			ps.execute();
			
			createtable = "CREATE TABLE IF NOT EXISTS proadb.units ("
					+ "code VARCHAR(7) NOT NULL,"
					+ "name varchar(100) NOT NULL,"
					+ "discipline varchar(4) NOT NULL, "
					+ "2boffered INT NULL,"
					+ "2breviewed INT NULL,"
					+ "nlic varchar(45) NULL,"
					+ "at1 LONGBLOB NULL, "
					+ "at2 LONGBLOB NULL, "
					+ "at3 LONGBLOB NULL, "
					+ "at1_status varchar(20) NULL, "
					+ "at2_status varchar(20) NULL, "
					+ "at3_status varchar(20) NULL, "
					+ "at1_feedback varchar(200) NULL, "
					+ "at2_feedback varchar(200) NULL, "
					+ "at3_feedback varchar(200) NULL, "
					+ "at1_type varchar(5) NULL, "
					+ "at2_type varchar(5) NULL, "
					+ "at3_type varchar(5) NULL, "
					+ "reviewer1 varchar(45) NULL, "
					+ "reviewer2 varchar(45) NULL, "
					+ "reviewer3 varchar(45) NULL, "
					+ "reviewer1_at1 LONGBLOB NULL, "
					+ "reviewer1_at2 LONGBLOB NULL, "
					+ "reviewer1_at3 LONGBLOB NULL, "
					+ "reviewer2_at1 LONGBLOB NULL, "
					+ "reviewer2_at2 LONGBLOB NULL, "
					+ "reviewer2_at3 LONGBLOB NULL, "
					+ "reviewer3_at1 LONGBLOB NULL, "
					+ "reviewer3_at2 LONGBLOB NULL, "
					+ "reviewer3_at3 LONGBLOB NULL, "				
					+ "PRIMARY KEY (code)) "
					+ " ENGINE = InnoDB DEFAULT CHARACTER SET = utf8";// SQL statement for loading data

			ps = conn.prepareStatement(createtable);
			ps.execute();
			
			ps.close();
		} catch(Exception e) {
			//Handle errors 
			e.printStackTrace();
		}

		return conn;
	}
	
	// remove the account from the database
	public void removeLogin(String email) {
		try {
			// load and register JDBC driver for MySQL
			Class.forName("com.mysql.cj.jdbc.Driver");
			// establish a connection to the database
			Connection conn = DriverManager.getConnection(Configuration.dbConnectionURL);
			// prepare a SQl statement
			PreparedStatement ps=conn.prepareStatement("delete from login where email = ?"); 
			// provide parameter values
			ps.setString(1, email);
			// execute sql query
			ps.executeUpdate();

			// statement and connection
			ps.close();
			conn.close();

		} catch(Exception e) {
			//Handle errors for Class.forName
			e.printStackTrace();
		}
	}

	// update the account with the specified email
	/* Sprint 1 needs to complete this method
	 * if activation code acticode is null, it is called by the approver to generate the code 
	 * and save the code into the login table. if activation code acticode is not null, it is called
	 * by the user to activate the account.
	 * Hints: 
	 * 1. if (acticode == null), use the following code to generate 10-digit activation code
	 * 		acticode = RandomStringUtils.randomAlphanumeric(10);
	 * 2. save the code into login table using update statement
	 * 3. if (acticode != null), set activated =1 using update statement
	 */
	public String updateLogin(String acticode, String email) {
		try {
			Class.forName("com.mysql.cj.jdbc.Driver");
			Connection conn = DriverManager.getConnection(Configuration.dbConnectionURL);

			if (acticode == null) {
				acticode = RandomStringUtils.randomAlphabetic(10);
			} else {
				PreparedStatement ps = conn.prepareStatement("UPDATE proadb.login SET activated = 1 WHERE email = ?");
				ps.setString(1, email);
				ps.execute();
			}
			PreparedStatement ps = conn.prepareStatement("UPDATE proadb.login SET acticode = ? WHERE email = ?");
			ps.setString(1, acticode);
			ps.setString(2, email);
			return acticode;
		} catch (Exception e) {
			e.printStackTrace();
		}
		return acticode;
	}
	
	// change the current user's password
	public int changePassword() {
		int changeCode = -1; //1: successful, 0: incorrect email or password, -1: error

		try {
			Class.forName("com.mysql.cj.jdbc.Driver");
			// establish a connection to the database
			Connection conn = DriverManager.getConnection(Configuration.dbConnectionURL);
			// ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE options allow
			// making changes to the table using 'select'
			PreparedStatement ps=conn.prepareStatement("select * from login where email=?", ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE); 
			// provide parameter values
			ps.setString(1, email);
			// execute sql query
			ResultSet rs = ps.executeQuery();
			
			if (rs.next()) {				
				// password matches the stored password
				if (BCrypt.checkpw(password, rs.getString("password"))) {
					// change password in the table
					String hashednewpw = BCrypt.hashpw(passwordNew, BCrypt.gensalt(12));
					rs.updateString("password", hashednewpw);
					rs.updateRow();
					changeCode = 1;	
				} else {
					changeCode = 0;	
				} 
			} else {
				changeCode = 0;	
			} 
						
			rs.close();
			ps.close();
			conn.close();
						
		 } catch(Exception e) {
	         //Handle errors for Class.forName
	         e.printStackTrace();
			 changeCode = -1;
	    }
			
		return changeCode;
	}
	
	// return user info
	public String getUser(String email) {
		String user = "";
		try {
			// load and register JDBC driver for MySQL
			Class.forName("com.mysql.cj.jdbc.Driver");
			// establish a connection to the database
			Connection conn = DriverManager.getConnection(Configuration.dbConnectionURL);
			// prepare a SQl statement
			PreparedStatement ps=conn.prepareStatement("select * from login where email = ?"); 
			// provide parameter values
			ps.setString(1, email);
			// execute sql query
			ResultSet rs = ps.executeQuery();

			// both email and password match
			if (rs.next()) {
				user = rs.getString("firstname") + " " + rs.getString("lastname");	
			}

			// close resultset, statement and connection
			rs.close();
			ps.close();
			conn.close();

		} catch(Exception e) {
			//Handle errors for Class.forName
			e.printStackTrace();
		}

		return user;
	}
}
