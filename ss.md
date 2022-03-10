<table BORDER=1 CELLSPACING=0 CELLPADDING=0"
       <tr bgcolor="#CCCC99">
       <th><font face="arial" color="#336699">Theme</th>
       <th><font face="arial" color="#336699">Weight</th>
       </tr>
<%
    while ( rset.next() ) {
 
      theme  = rset.getString(1); 
      weight = (int)rset.getInt(2);
%>
       <tr bgcolor="ffffe0">
         <td align="center"><font face="arial"><b> <%= theme  %> </b></font></td>
         <td align="center"><font face="arial"> <%= weight %></font></td>
       </tr>
<%
    }
 %>
</table>