with Ada.Containers; use Ada.Containers;

package body Hash_Join is

   -- Helper function to hash Key_Type for the Ada.Containers.Hashed_Maps
   function Hash_Key (K : Key_Type) return Hash_Type is
   begin
      return Hash_Type (abs Integer (K));
   end Hash_Key;

   -- Helper package to store multiple Left_Tuples per key (for N:M joins)
   package Left_Tuple_Lists is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Left_Tuple);

   -- In-memory Hash Table structure
   package Hash_Tables is new Ada.Containers.Hashed_Maps
     (Key_Type        => Key_Type,
      Element_Type    => Left_Tuple_Lists.Vector,
      Hash            => Hash_Key,
      Equivalent_Keys => "=",
      "="             => Left_Tuple_Lists."=");

   -- Partition Hash Helper (Returns 0 to Num_Partitions - 1)
   function Get_Partition (K : Key_Type; Num_Partitions : Natural) return Natural is
   begin
      return Natural (abs Integer (K)) mod Num_Partitions;
   end Get_Partition;


   ----------------------------------------------------------------------------
   -- Classic_Hash_Join
   ----------------------------------------------------------------------------
   function Classic_Hash_Join 
     (R : Relation_R.Vector; 
      S : Relation_S.Vector) return Relation_Joined.Vector 
   is
      Result : Relation_Joined.Vector;
      HT     : Hash_Tables.Map;
   begin
      -- Build Phase: Hash Relation R
      for C of R loop
         if not HT.Contains (C.Key) then
            declare
               New_List : Left_Tuple_Lists.Vector;
            begin
               New_List.Append (C);
               HT.Insert (Key => C.Key, New_Item => New_List);
            end;
         else
            declare
               List : Left_Tuple_Lists.Vector := HT.Element (C.Key);
            begin
               List.Append (C);
               HT.Replace (Key => C.Key, New_Item => List);
            end;
         end if;
      end loop;

      -- Probe Phase: Scan Relation S and probe Hash Table
      for C of S loop
         if HT.Contains (C.Key) then
            declare
               Matching_Lefts : constant Left_Tuple_Lists.Vector := HT.Element (C.Key);
            begin
               for L_Tuple of Matching_Lefts loop
                  Result.Append (
                     (Key        => C.Key,
                      Left_Data  => L_Tuple.Data,
                      Right_Data => C.Data)
                  );
               end loop;
            end;
         end if;
      end loop;

      return Result;
   end Classic_Hash_Join;


   ----------------------------------------------------------------------------
   -- Grace_Hash_Join
   ----------------------------------------------------------------------------
   function Grace_Hash_Join 
     (R              : Relation_R.Vector; 
      S              : Relation_S.Vector;
      Num_Partitions : Natural) return Relation_Joined.Vector 
   is
      Result : Relation_Joined.Vector;
      
      type R_Array is array (0 .. Num_Partitions - 1) of Relation_R.Vector;
      type S_Array is array (0 .. Num_Partitions - 1) of Relation_S.Vector;
      
      Partitions_R : R_Array;
      Partitions_S : S_Array;
      P_Idx        : Natural;
   begin
      if Num_Partitions = 0 then
         raise Invalid_Partition_Count with "Number of partitions must be > 0";
      end if;

      -- Partition Phase: Relation R
      for Tuple_R of R loop
         P_Idx := Get_Partition (Tuple_R.Key, Num_Partitions);
         Partitions_R (P_Idx).Append (Tuple_R);
      end loop;

      -- Partition Phase: Relation S
      for Tuple_S of S loop
         P_Idx := Get_Partition (Tuple_S.Key, Num_Partitions);
         Partitions_S (P_Idx).Append (Tuple_S);
      end loop;

      -- Join Phase: Classic join on each partition
      for I in 0 .. Num_Partitions - 1 loop
         declare
            Sub_Result : Relation_Joined.Vector;
         begin
            Sub_Result := Classic_Hash_Join (Partitions_R (I), Partitions_S (I));
            Result.Append (Sub_Result);
         end;
      end loop;

      return Result;
   end Grace_Hash_Join;


   ----------------------------------------------------------------------------
   -- Hybrid_Hash_Join
   ----------------------------------------------------------------------------
   function Hybrid_Hash_Join 
     (R              : Relation_R.Vector; 
      S              : Relation_S.Vector;
      Num_Partitions : Natural) return Relation_Joined.Vector 
   is
      Result : Relation_Joined.Vector;
      
      type R_Array is array (1 .. Num_Partitions - 1) of Relation_R.Vector;
      type S_Array is array (1 .. Num_Partitions - 1) of Relation_S.Vector;
      
      Partitions_R : R_Array;
      Partitions_S : S_Array;
      
      HT_Partition_0 : Hash_Tables.Map;
      P_Idx          : Natural;
   begin
      if Num_Partitions = 0 then
         raise Invalid_Partition_Count with "Number of partitions must be > 0";
      end if;

      -- Partition Phase R: Partition 0 stays in memory as Hash Table
      for Tuple_R of R loop
         P_Idx := Get_Partition (Tuple_R.Key, Num_Partitions);
         if P_Idx = 0 then
            if not HT_Partition_0.Contains (Tuple_R.Key) then
               declare
                  New_List : Left_Tuple_Lists.Vector;
               begin
                  New_List.Append (Tuple_R);
                  HT_Partition_0.Insert (Tuple_R.Key, New_List);
               end;
            else
               declare
                  List : Left_Tuple_Lists.Vector := HT_Partition_0.Element (Tuple_R.Key);
               begin
                  List.Append (Tuple_R);
                  HT_Partition_0.Replace (Tuple_R.Key, List);
               end;
            end if;
         else
            Partitions_R (P_Idx).Append (Tuple_R);
         end if;
      end loop;

      -- Partition Phase S: Probe Partition 0 immediately, partition the rest
      for Tuple_S of S loop
         P_Idx := Get_Partition (Tuple_S.Key, Num_Partitions);
         if P_Idx = 0 then
            if HT_Partition_0.Contains (Tuple_S.Key) then
               declare
                  Matching_Lefts : constant Left_Tuple_Lists.Vector := HT_Partition_0.Element (Tuple_S.Key);
               begin
                  for L_Tuple of Matching_Lefts loop
                     Result.Append (
                        (Key        => Tuple_S.Key,
                         Left_Data  => L_Tuple.Data,
                         Right_Data => Tuple_S.Data)
                     );
                  end loop;
               end;
            end if;
         else
            Partitions_S (P_Idx).Append (Tuple_S);
         end if;
      end loop;

      -- Join Phase: Classic join on remaining partitions (1 to N-1)
      for I in 1 .. Num_Partitions - 1 loop
         declare
            Sub_Result : Relation_Joined.Vector;
         begin
            Sub_Result := Classic_Hash_Join (Partitions_R (I), Partitions_S (I));
            Result.Append (Sub_Result);
         end;
      end loop;

      return Result;
   end Hybrid_Hash_Join;

end Hash_Join;
