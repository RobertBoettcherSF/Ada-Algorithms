pragma Ada_2022;
package body Design_Skiplist_Lite with SPARK_Mode => On is
   function Empty return Skiplist is
   begin return (Data => (others => 0), Count_Stored => 0); end Empty;
   function Size (S : Skiplist) return Count is
   begin return S.Count_Stored; end Size;
   function Height (V : Value) return Level is
   begin
      if V mod 4 = 0 then return 4; elsif V mod 2 = 0 then return 2; else return 1; end if;
   end Height;
   procedure Insert (S : in out Skiplist; V : Value) is
   begin
      case S.Count_Stored is
         when 0 => S.Data (1) := V; when 1 => S.Data (2) := V;
         when 2 => S.Data (3) := V; when 3 => S.Data (4) := V;
         when 4 => S.Data (5) := V; when 5 => S.Data (6) := V;
         when 6 => S.Data (7) := V; when 7 => S.Data (8) := V;
         when 8 => null;
      end case;
      if S.Count_Stored < Capacity then S.Count_Stored := S.Count_Stored + 1; end if;
   end Insert;
   function First (S : Skiplist) return Value is
   begin return S.Data (1); end First;
end Design_Skiplist_Lite;
