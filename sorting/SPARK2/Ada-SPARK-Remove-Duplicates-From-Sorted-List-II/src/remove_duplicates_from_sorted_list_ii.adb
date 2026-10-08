pragma SPARK_Mode (On);
package body Remove_Duplicates_From_Sorted_List_II is
   function Empty return List is
   begin
      return (Data => [others => 0], Length => 0);
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
      --  the proof only needs Unique_At as a black box
      pragma Annotate (GNATprove, Hide_Info, "Expression_Function_Body", Unique_At);
      Original : constant List := L;
      Write : Count := 0;
      From : array (Position) of Position := [others => 1] with Ghost;   --  output P came from input From (P)
   begin
      for I in 1 .. Original.Length loop
         if Unique_At (Original, I) then
            Write := Write + 1;
            L.Data (Write) := Original.Data (I);
            From (Write) := I;
         end if;
         pragma Loop_Invariant (Write <= I);
         pragma Loop_Invariant (for all P in 1 .. Write =>
                                  From (P) <= I and then Unique_At (Original, From (P))
                                  and then L.Data (P) = Original.Data (From (P)));
         pragma Loop_Invariant (for all I2 in 1 .. I =>
                                  (if Unique_At (Original, I2) then
                                     (for some P in 1 .. Write => From (P) = I2)));
      end loop;
      L.Length := Write;
      pragma Assert (for all P in 1 .. Write =>
                       From (P) in 1 .. Original.Length and then Unique_At (Original, From (P))
                       and then L.Data (P) = Original.Data (From (P)));
   end Solve;
end Remove_Duplicates_From_Sorted_List_II;
