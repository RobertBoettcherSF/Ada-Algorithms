pragma SPARK_Mode (On);
package body Design_HashSet is
   function Empty return Set is
   begin
      return (Present => (others => False));
   end Empty;
   procedure Add (S : in out Set; E : Element) is
   begin
      S.Present (E) := True;
   end Add;
   procedure Remove (S : in out Set; E : Element) is
   begin
      S.Present (E) := False;
   end Remove;
   function Contains (S : Set; E : Element) return Boolean is
   begin
      return S.Present (E);
   end Contains;
end Design_HashSet;
