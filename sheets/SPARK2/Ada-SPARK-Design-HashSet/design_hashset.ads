pragma SPARK_Mode (On);
package Design_HashSet is
   Capacity : constant := 8;
   subtype Element is Positive range 1 .. Capacity;
   type Set is private;
   function Empty return Set with Global => null;
   procedure Add (S : in out Set; E : Element) with Global => null;
   procedure Remove (S : in out Set; E : Element) with Global => null;
   function Contains (S : Set; E : Element) return Boolean with Global => null;
private
   type Membership is array (Element) of Boolean;
   type Set is record
      Present : Membership := (others => False);
   end record;
end Design_HashSet;
