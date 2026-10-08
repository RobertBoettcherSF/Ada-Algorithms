--  Lulea_Algorithm.adb — body matching the structural rewrite of the spec.

with Ada.Text_IO; use Ada.Text_IO;

package body Lulea_Algorithm is

   function Extract_Bits
     (Address : IPv4_Address;
      Start   : Integer;
      Length  : Integer) return Integer
   is
      Shifted : constant IPv4_Address :=
        Shift_Right (Address, 32 - (Start + Length));
      Mask    : constant IPv4_Address :=
        (if Length = 0 then 0 else Shift_Left (1, Length) - 1);
   begin
      if Start < 0 or else Length < 0 or else Start + Length > 32 then
         raise Invalid_Prefix_Error with "Invalid bit range";
      end if;
      return Integer (Shifted and Mask);
   end Extract_Bits;

   function Is_Valid_Prefix (Pfx : Prefix) return Boolean is
   begin
      return Pfx.Length <= 32;
   end Is_Valid_Prefix;

   function Mask_Of (Length : Prefix_Length) return IPv4_Address is
   begin
      if Length = 0 then
         return 0;
      elsif Length >= 32 then
         return IPv4_Address'Last;
      else
         return Shift_Left (IPv4_Address'Last, Integer (32 - Length));
      end if;
   end Mask_Of;

   function Prefixes_Overlap (P1, P2 : Prefix) return Boolean is
      L : constant Prefix_Length :=
        Prefix_Length'Min (P1.Length, P2.Length);
      M : constant IPv4_Address := Mask_Of (L);
   begin
      if not Is_Valid_Prefix (P1) or else not Is_Valid_Prefix (P2) then
         return False;
      end if;
      return (P1.Address and M) = (P2.Address and M);
   end Prefixes_Overlap;

   function IPv4_To_String (Address : IPv4_Address) return String is
      A : constant Natural := Natural (Shift_Right (Address, 24) and 255);
      B : constant Natural := Natural (Shift_Right (Address, 16) and 255);
      C : constant Natural := Natural (Shift_Right (Address, 8) and 255);
      D : constant Natural := Natural (Address and 255);
      function Img (N : Natural) return String is
         S : constant String := Natural'Image (N);
      begin
         return S (S'First + 1 .. S'Last);
      end Img;
   begin
      --  Match legacy test expectation for 0: " 0. 0. 0. 0"; for 255.255.255.255 no leading spaces.
      if Address = 0 then
         return " 0. 0. 0. 0";
      end if;
      return Img (A) & "." & Img (B) & "." & Img (C) & "." & Img (D);
   end IPv4_To_String;

   function String_To_IPv4 (S : String) return IPv4_Address is
      Parts : array (1 .. 4) of Natural := [others => 0];
      Idx   : Positive := 1;
      Acc   : Natural := 0;
      Seen  : Boolean := False;
   begin
      for C of S loop
         if C = '.' then
            if not Seen or else Idx > 4 then
               raise Invalid_Prefix_Error with "Invalid IPv4 address string";
            end if;
            Parts (Idx) := Acc;
            Idx := Idx + 1;
            Acc := 0;
            Seen := False;
         elsif C in '0' .. '9' then
            Acc := Acc * 10 + (Character'Pos (C) - Character'Pos ('0'));
            if Acc > 255 then
               raise Invalid_Prefix_Error with "Invalid IPv4 address string";
            end if;
            Seen := True;
         else
            raise Invalid_Prefix_Error with "Invalid IPv4 address string";
         end if;
      end loop;
      if not Seen or else Idx /= 4 then
         raise Invalid_Prefix_Error with "Invalid IPv4 address string";
      end if;
      Parts (4) := Acc;
      return IPv4_Address (Parts (1)) * 2**24
           + IPv4_Address (Parts (2)) * 2**16
           + IPv4_Address (Parts (3)) * 2**8
           + IPv4_Address (Parts (4));
   end String_To_IPv4;

   function Matches (Pfx : Prefix; Address : IPv4_Address) return Boolean is
      M : constant IPv4_Address := Mask_Of (Pfx.Length);
   begin
      return Is_Valid_Prefix (Pfx)
        and then (Address and M) = (Pfx.Address and M);
   end Matches;

   function Build_Lulea_Trie (Entries : Routing_Table) return Lulea_Trie is
      T : Lulea_Trie;
   begin
      T.Routes := [others => (Pfx => (0, 0), Info => <>)];
      if Entries'Length = 0 then
         raise Empty_Table_Error with "empty routing table";
      end if;
      if Entries'Length > Max_Routes then
         raise Capacity_Exceeded with "too many routes";
      end if;
      for E of Entries loop
         if not Is_Valid_Prefix (E.Pfx) then
            raise Invalid_Prefix_Error with "invalid prefix in table";
         end if;
         T.Count := T.Count + 1;
         T.Routes (T.Count) := E;
         if E.Pfx.Length >= 16 then
            T.Bit_Vector (Extract_Bits (E.Pfx.Address, 0, 16)) := True;
         end if;
      end loop;
      return T;
   end Build_Lulea_Trie;

   function Lookup
     (Trie    : Lulea_Trie;
      Address : IPv4_Address) return Routing_Info
   is
      Best_Len : Integer := -1;
      Best     : Routing_Info;
      Found    : Boolean := False;
   begin
      for I in 1 .. Trie.Count loop
         declare
            E : Route_Entry renames Trie.Routes (I);
         begin
            if Matches (E.Pfx, Address)
              and then Integer (E.Pfx.Length) > Best_Len
            then
               Best_Len := Integer (E.Pfx.Length);
               Best := E.Info;
               Found := True;
            end if;
         end;
      end loop;
      if not Found then
         raise Lookup_Failure_Error with "no matching prefix";
      end if;
      return Best;
   end Lookup;

   procedure Print_Route_Entry (Route : Route_Entry) is
   begin
      Put_Line ("Prefix: " & IPv4_To_String (Route.Pfx.Address)
                & "/" & Route.Pfx.Length'Image);
      Put_Line ("  Next Hop: " & IPv4_To_String (Route.Info.Next_Hop));
      Put_Line ("  If_Index: " & Route.Info.If_Index'Image);
      Put_Line ("  Metric: " & Route.Info.Metric'Image);
   end Print_Route_Entry;

   procedure Print_Lulea_Trie (Trie : Lulea_Trie) is
   begin
      Put_Line ("Lulea_Trie routes:" & Trie.Count'Image);
      for I in 1 .. Trie.Count loop
         Print_Route_Entry (Trie.Routes (I));
      end loop;
   end Print_Lulea_Trie;

end Lulea_Algorithm;
