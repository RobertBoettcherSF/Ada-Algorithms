pragma SPARK_Mode (On);

package Design_Twitter_Lite is
   Message_Count : constant := 8;
   subtype Message_Id is Natural range 0 .. 1000;
   type Message_Array is array (Positive range 1 .. Message_Count) of Message_Id;
   type Active_Array is array (Positive range 1 .. Message_Count) of Boolean;

   function Feed_Size
     (Messages : Message_Array; Active : Active_Array) return Natural;
end Design_Twitter_Lite;
