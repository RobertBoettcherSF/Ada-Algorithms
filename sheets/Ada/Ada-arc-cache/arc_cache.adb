-- arc_cache.adb
pragma Ada_2012;

package body ARC_Cache is

   procedure Replace (C : in out Cache; Key : Key_Type; P : Integer) is
      use Key_Lists;
      Evicted : Boolean := False;

      --  Helper to evict the oldest unlocked entry from a target list to its ghost list
      procedure Try_Evict (From_T : List_Kind; To_B : List_Kind; Success : out Boolean) is
         Curr : Cursor := Last (C.Lists (From_T));
      begin
         Success := False;
         while Has_Element (Curr) loop
            declare
               Item_Key : constant Key_Type := Element (Curr);
               Ent : Cache_Entry := C.Map.Element (Item_Key);
            begin
               if not Ent.Locked then
                  C.Lists (From_T).Delete (Curr);
                  C.Lists (To_B).Prepend (Item_Key);
                  
                  Ent.Kind := To_B;
                  Ent.Pos := First (C.Lists (To_B));
                  C.Map.Replace (Item_Key, Ent);
                  Success := True;
                  return;
               end if;
            end;
            Curr := Previous (Curr);
         end loop;
      end Try_Evict;

   begin
      if not C.Lists (In_T1).Is_Empty and then
         (Integer (C.Lists (In_T1).Length) > P or else
          (C.Map.Contains (Key) and then C.Map.Element (Key).Kind = In_B2 and then Integer (C.Lists (In_T1).Length) = P))
      then
         Try_Evict (In_T1, In_B1, Evicted);
         if not Evicted then
            Try_Evict (In_T2, In_B2, Evicted);
         end if;
      else
         Try_Evict (In_T2, In_B2, Evicted);
         if not Evicted then
            Try_Evict (In_T1, In_B1, Evicted);
         end if;
      end if;

      if not Evicted then
         raise Cache_Full_Of_Locked_Pages;
      end if;
   end Replace;

   procedure Put_Internal (C : in out Cache; Key : Key_Type; Value : Value_Type; Lock_It : Boolean) is
      use Key_Lists;
      use Ada.Containers;
      Ent   : Cache_Entry;
      C_Cap : constant Count_Type := C.Capacity;
   begin
      if C.Map.Contains (Key) then
         Ent := C.Map.Element (Key);

         if Ent.Kind = In_T1 or Ent.Kind = In_T2 then
            -- Cache Hit
            Ent.Value := Value;
            if Lock_It then
               Ent.Locked := True;
            end if;

            C.Lists (Ent.Kind).Delete (Ent.Pos);
            C.Lists (In_T2).Prepend (Key);
            Ent.Kind := In_T2;
            Ent.Pos := First (C.Lists (In_T2));

            C.Map.Replace (Key, Ent);
            return;

         elsif Ent.Kind = In_B1 then
            -- Ghost Hit in B1
            declare
               Len_B1  : constant Integer := Integer (C.Lists (In_B1).Length);
               Len_B2  : constant Integer := Integer (C.Lists (In_B2).Length);
               Delta_P : Integer := 1;
            begin
               if Len_B1 < Len_B2 then
                  Delta_P := Len_B2 / Integer'Max (1, Len_B1);
               end if;
               C.P := Integer'Min (Integer (C_Cap), C.P + Delta_P);
            end;

            Replace (C, Key, C.P);

            C.Lists (In_B1).Delete (Ent.Pos);
            C.Lists (In_T2).Prepend (Key);

            Ent.Value := Value;
            Ent.Kind := In_T2;
            Ent.Pos := First (C.Lists (In_T2));
            Ent.Locked := Lock_It;
            C.Map.Replace (Key, Ent);
            return;

         elsif Ent.Kind = In_B2 then
            -- Ghost Hit in B2
            declare
               Len_B1  : constant Integer := Integer (C.Lists (In_B1).Length);
               Len_B2  : constant Integer := Integer (C.Lists (In_B2).Length);
               Delta_P : Integer := 1;
            begin
               if Len_B2 < Len_B1 then
                  Delta_P := Len_B1 / Integer'Max (1, Len_B2);
               end if;
               C.P := Integer'Max (0, C.P - Delta_P);
            end;

            Replace (C, Key, C.P);

            C.Lists (In_B2).Delete (Ent.Pos);
            C.Lists (In_T2).Prepend (Key);

            Ent.Value := Value;
            Ent.Kind := In_T2;
            Ent.Pos := First (C.Lists (In_T2));
            Ent.Locked := Lock_It;
            C.Map.Replace (Key, Ent);
            return;
         end if;
      end if;

      -- Cache Miss
      declare
         Len_T1 : constant Count_Type := C.Lists (In_T1).Length;
         Len_B1 : constant Count_Type := C.Lists (In_B1).Length;
         Len_T2 : constant Count_Type := C.Lists (In_T2).Length;
         Len_B2 : constant Count_Type := C.Lists (In_B2).Length;
      begin
         if Len_T1 + Len_B1 = C_Cap then
            if Len_T1 < C_Cap then
               declare
                  Old_Key : constant Key_Type := Element (Last (C.Lists (In_B1)));
               begin
                  C.Lists (In_B1).Delete_Last;
                  C.Map.Delete (Old_Key);
               end;
               Replace (C, Key, C.P);
            else
               declare
                  Old_Key : Key_Type;
                  Found_Unlocked : Boolean := False;
                  Curr : Key_Lists.Cursor := Last (C.Lists (In_T1));
               begin
                  while Has_Element (Curr) loop
                     Old_Key := Element (Curr);
                     if not C.Map.Element (Old_Key).Locked then
                        C.Lists (In_T1).Delete (Curr);
                        C.Map.Delete (Old_Key);
                        Found_Unlocked := True;
                        exit;
                     end if;
                     Curr := Previous (Curr);
                  end loop;

                  if not Found_Unlocked then
                     raise Cache_Full_Of_Locked_Pages;
                  end if;
               end;
            end if;
         elsif Len_T1 + Len_B1 < C_Cap and then Len_T1 + Len_T2 + Len_B1 + Len_B2 >= C_Cap then
            if Len_T1 + Len_T2 + Len_B1 + Len_B2 = 2 * C_Cap then
               declare
                  Old_Key : constant Key_Type := Element (Last (C.Lists (In_B2)));
               begin
                  C.Lists (In_B2).Delete_Last;
                  C.Map.Delete (Old_Key);
               end;
            end if;
            Replace (C, Key, C.P);
         end if;
      end;

      -- Add the new cache entry to MRU position of T1
      C.Lists (In_T1).Prepend (Key);
      
      declare
         New_Ent : Cache_Entry;
      begin
         New_Ent.Value  := Value;
         New_Ent.Kind   := In_T1;
         New_Ent.Pos    := First (C.Lists (In_T1));
         New_Ent.Locked := Lock_It;
         C.Map.Insert (Key, New_Ent);
      end;

   end Put_Internal;

   procedure Put (C : in out Cache; Key : Key_Type; Value : Value_Type) is
   begin
      Put_Internal (C, Key, Value, False);
   end Put;

   procedure Put_Locked (C : in out Cache; Key : Key_Type; Value : Value_Type) is
   begin
      Put_Internal (C, Key, Value, True);
   end Put_Locked;

   function Get_Internal (C : in out Cache; Key : Key_Type; Value : out Value_Type; Lock_It : Boolean) return Boolean is
      use Key_Lists;
      Ent : Cache_Entry;
   begin
      if C.Map.Contains (Key) then
         Ent := C.Map.Element (Key);
         if Ent.Kind = In_T1 or Ent.Kind = In_T2 then
            Value := Ent.Value;

            C.Lists (Ent.Kind).Delete (Ent.Pos);
            C.Lists (In_T2).Prepend (Key);
            Ent.Kind := In_T2;
            Ent.Pos  := First (C.Lists (In_T2));

            if Lock_It then
               Ent.Locked := True;
            end if;

            C.Map.Replace (Key, Ent);
            return True;
         end if;
      end if;
      return False;
   end Get_Internal;

   function Get (C : in out Cache; Key : Key_Type; Value : out Value_Type) return Boolean is
   begin
      return Get_Internal (C, Key, Value, False);
   end Get;

   function Get_Locked (C : in out Cache; Key : Key_Type; Value : out Value_Type) return Boolean is
   begin
      return Get_Internal (C, Key, Value, True);
   end Get_Locked;

   procedure Unlock (C : in out Cache; Key : Key_Type) is
      Ent : Cache_Entry;
   begin
      if C.Map.Contains (Key) then
         Ent := C.Map.Element (Key);
         if (Ent.Kind = In_T1 or Ent.Kind = In_T2) and then Ent.Locked then
            Ent.Locked := False;
            C.Map.Replace (Key, Ent);
         end if;
      end if;
   end Unlock;

   function Is_Locked (C : Cache; Key : Key_Type) return Boolean is
   begin
      if C.Map.Contains (Key) then
         return C.Map.Element (Key).Locked;
      end if;
      return False;
   end Is_Locked;

end ARC_Cache;
