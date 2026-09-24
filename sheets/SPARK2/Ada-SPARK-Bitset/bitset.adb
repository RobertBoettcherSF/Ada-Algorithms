pragma Ada_2022;
package body Bitset with SPARK_Mode => On is
   procedure Initialize (S : out Set) is begin for I in Bit_Index loop S.Data (I) := False; end loop; end Initialize;
   procedure Include (S : in out Set; Bit : Bit_Index) is begin S.Data (Bit) := True; end Include;
   procedure Exclude (S : in out Set; Bit : Bit_Index) is begin S.Data (Bit) := False; end Exclude;
   function Contains (S : Set; Bit : Bit_Index) return Boolean is begin return S.Data (Bit); end Contains;
   function Cardinality (S : Set) return Natural is Result : Natural := 0;
   begin for I in Bit_Index loop if S.Data (I) and then Result < Capacity then Result := Result + 1; end if; end loop; return Result; end Cardinality;
end Bitset;
