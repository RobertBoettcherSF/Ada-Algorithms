pragma SPARK_Mode (On);
package body Remove_Duplicates_From_Sorted_List is
   function Empty return List is
   begin
      return (Data => (others => 0), Length => 0);
   end Empty;
   procedure Append (L : in out List; Value : Integer) is
   begin
      L.Length := L.Length + 1;
      L.Data (L.Length) := Value;
   end Append;
   function Get (L : List; P : Position) return Integer is
   begin
      return L.Data (P);
   end Get;
   procedure Solve (L : in out List) is
      Original : constant Values := L.Data;
      Write : Count := 0;
      Previous : Integer := 0;
      Have_Previous : Boolean := False;
   begin
      for I in Position loop
         if I <= L.Length and then (not Have_Previous or else Original (I) /= Previous) then
            if Write < Capacity then
               Write := Write + 1;
               L.Data (Write) := Original (I);
               Previous := Original (I);
               Have_Previous := True;
            end if;
         end if;
      end loop;
      L.Length := Write;
   end Solve;
end Remove_Duplicates_From_Sorted_List;
