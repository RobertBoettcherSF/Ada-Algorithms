with Ada.Strings.Fixed;

package body Financial_Information_Exchange is

   -----------------------------------------------------------------------------
   -- Private Helper: Format Checksum as exactly 3 digits
   -----------------------------------------------------------------------------
   function Format_Checksum (Val : Checksum_Value) return String is
      Trimmed : constant String := Ada.Strings.Fixed.Trim (Checksum_Value'Image (Val), Ada.Strings.Both);
   begin
      if Trimmed'Length = 1 then
         return "00" & Trimmed;
      elsif Trimmed'Length = 2 then
         return "0" & Trimmed;
      else
         return Trimmed;
      end if;
   end Format_Checksum;

   -----------------------------------------------------------------------------
   -- Core Operations
   -----------------------------------------------------------------------------
   function Empty_Message return Fix_Message is
      Result : Fix_Message;
   begin
      return Result;
   end Empty_Message;

   procedure Add_Field (Msg   : in out Fix_Message;
                        Tag   : Tag_Number;
                        Value : String) is
   begin
      -- Search for existing tag to overwrite
      for I in 1 .. Msg.Count loop
         if Msg.Fields (I).Tag = Tag then
            Msg.Fields (I).Value := To_Unbounded_String (Value);
            return;
         end if;
      end loop;

      -- Add new field if not found
      if Msg.Count >= Max_Fields then
         raise Capacity_Exceeded with "Maximum field count reached";
      end if;

      Msg.Count := Msg.Count + 1;
      Msg.Fields (Msg.Count) := (Tag => Tag, Value => To_Unbounded_String (Value));
   end Add_Field;

   function Has_Field (Msg : Fix_Message; Tag : Tag_Number) return Boolean is
   begin
      for I in 1 .. Msg.Count loop
         if Msg.Fields (I).Tag = Tag then
            return True;
         end if;
      end loop;
      return False;
   end Has_Field;

   function Get_Field (Msg : Fix_Message; Tag : Tag_Number) return String is
   begin
      for I in 1 .. Msg.Count loop
         if Msg.Fields (I).Tag = Tag then
            return To_String (Msg.Fields (I).Value);
         end if;
      end loop;
      -- Execution should never reach here due to Pre-condition, but for safety:
      raise Field_Not_Found with "Tag " & Tag_Number'Image (Tag) & " not found.";
   end Get_Field;

   -----------------------------------------------------------------------------
   -- Algorithms
   -----------------------------------------------------------------------------
   function Calculate_Checksum (Raw_Message : String) return Checksum_Value is
      Sum : Natural := 0;
   begin
      for C of Raw_Message loop
         Sum := Sum + Character'Pos (C);
      end loop;
      return Sum mod 256;
   end Calculate_Checksum;

   function Calculate_Body_Length (Msg : Fix_Message) return Natural is
      Len : Natural := 0;
   begin
      -- Body length equals the length of all fields except 8, 9, 10
      for I in 1 .. Msg.Count loop
         if Msg.Fields (I).Tag /= 8 and then
            Msg.Fields (I).Tag /= 9 and then
            Msg.Fields (I).Tag /= 10 
         then
            declare
               T_Img  : constant String := Tag_Number'Image (Msg.Fields (I).Tag);
               T_Trim : constant String := Ada.Strings.Fixed.Trim (T_Img, Ada.Strings.Both);
               V_Str  : constant String := To_String (Msg.Fields (I).Value);
            begin
               -- length of "Tag=Value<SOH>"
               Len := Len + T_Trim'Length + 1 + V_Str'Length + 1;
            end;
         end if;
      end loop;
      return Len;
   end Calculate_Body_Length;

   -----------------------------------------------------------------------------
   -- Serialization / Parsing
   -----------------------------------------------------------------------------
   function Serialize (Msg : Fix_Message) return String is
      Result       : Unbounded_String;
      Body_Len     : constant Natural := Calculate_Body_Length (Msg);
      Body_Len_Img : constant String  := Ada.Strings.Fixed.Trim (Natural'Image (Body_Len), Ada.Strings.Both);
      Header_8     : Unbounded_String := To_Unbounded_String ("FIX.4.2");
      Check_Val    : Checksum_Value;
   begin
      if Has_Field (Msg, 8) then
         Header_8 := To_Unbounded_String (Get_Field (Msg, 8));
      end if;

      -- Standard Tag 8 (BeginString) and Tag 9 (BodyLength)
      Append (Result, "8=" & To_String (Header_8) & SOH);
      Append (Result, "9=" & Body_Len_Img & SOH);

      -- Append Body Fields
      for I in 1 .. Msg.Count loop
         if Msg.Fields (I).Tag /= 8 and then
            Msg.Fields (I).Tag /= 9 and then
            Msg.Fields (I).Tag /= 10
         then
            declare
               T_Img : constant String := Ada.Strings.Fixed.Trim (Tag_Number'Image (Msg.Fields (I).Tag), Ada.Strings.Both);
            begin
               Append (Result, T_Img & "=" & To_String (Msg.Fields (I).Value) & SOH);
            end;
         end if;
      end loop;

      -- Calculate Checksum of the sequence constructed so far
      Check_Val := Calculate_Checksum (To_String (Result));

      -- Append Standard Tag 10 (Checksum)
      declare
         C_Img : constant String := Format_Checksum (Check_Val);
      begin
         Append (Result, "10=" & C_Img & SOH);
      end;

      return To_String (Result);
   end Serialize;

   function Parse (Raw_Message : String; Validate_Checksum : Boolean := True) return Fix_Message is
      Result    : Fix_Message := Empty_Message;
      Start_Idx : Positive    := Raw_Message'First;
      Eq_Idx    : Natural;
      SOH_Idx   : Natural;
      Tag_Val   : Tag_Number;
      Check_Str : constant String := "10=";
      Loc_10    : Natural;
   begin
      -- Optional checksum verification against standard
      if Validate_Checksum then
         Loc_10 := Ada.Strings.Fixed.Index (Raw_Message, Check_Str);
         if Loc_10 > Raw_Message'First then
            declare
               Expected : constant Checksum_Value := Calculate_Checksum (Raw_Message (Raw_Message'First .. Loc_10 - 1));
               Actual   : Checksum_Value;
               End_Idx  : constant Natural := Ada.Strings.Fixed.Index (Raw_Message (Loc_10 .. Raw_Message'Last), String'(1 => SOH));
            begin
               if End_Idx = 0 then
                  raise Malformed_Message with "Missing SOH after Checksum";
               end if;
               Actual := Checksum_Value'Value (Raw_Message (Loc_10 + 3 .. End_Idx - 1));
               if Expected /= Actual then
                  raise Invalid_Checksum with "Checksum mismatch.";
               end if;
            exception
               when Constraint_Error =>
                  raise Invalid_Checksum with "Malformed Checksum numeric value";
            end;
         end if;
      end if;

      -- Field extraction loop
      while Start_Idx <= Raw_Message'Last loop
         SOH_Idx := Ada.Strings.Fixed.Index (Raw_Message (Start_Idx .. Raw_Message'Last), String'(1 => SOH));
         
         if SOH_Idx = 0 then
            raise Malformed_Message with "Missing SOH delimiter in body";
         end if;

         Eq_Idx := Ada.Strings.Fixed.Index (Raw_Message (Start_Idx .. SOH_Idx - 1), "=");
         if Eq_Idx = 0 then
            raise Malformed_Message with "Missing '=' in field structure";
         end if;

         begin
            Tag_Val := Tag_Number'Value (Raw_Message (Start_Idx .. Eq_Idx - 1));
            Add_Field (Result, Tag_Val, Raw_Message (Eq_Idx + 1 .. SOH_Idx - 1));
         exception
            when Constraint_Error =>
               raise Malformed_Message with "Invalid Tag Number encountered";
         end;

         Start_Idx := SOH_Idx + 1;
      end loop;

      return Result;
   end Parse;

   -----------------------------------------------------------------------------
   -- Message Variants
   -----------------------------------------------------------------------------
   function Create_Heartbeat (Sender_Comp_ID : String;
                              Target_Comp_ID : String) return Fix_Message is
      Msg : Fix_Message := Empty_Message;
   begin
      Add_Field (Msg, 35, "0");
      Add_Field (Msg, 49, Sender_Comp_ID);
      Add_Field (Msg, 56, Target_Comp_ID);
      return Msg;
   end Create_Heartbeat;

   function Create_New_Order_Single (Sender_Comp_ID : String;
                                     Target_Comp_ID : String;
                                     Symbol         : String;
                                     Side           : String;
                                     Order_Qty      : Positive;
                                     Price          : Float) return Fix_Message is
      Msg : Fix_Message := Empty_Message;
      Qty_Img : constant String := Ada.Strings.Fixed.Trim (Positive'Image (Order_Qty), Ada.Strings.Both);
      Px_Img  : constant String := Ada.Strings.Fixed.Trim (Float'Image (Price), Ada.Strings.Both);
   begin
      Add_Field (Msg, 35, "D");
      Add_Field (Msg, 49, Sender_Comp_ID);
      Add_Field (Msg, 56, Target_Comp_ID);
      Add_Field (Msg, 55, Symbol);
      Add_Field (Msg, 54, Side);
      Add_Field (Msg, 38, Qty_Img);
      Add_Field (Msg, 44, Px_Img);
      return Msg;
   end Create_New_Order_Single;

   function Create_Execution_Report (Sender_Comp_ID : String;
                                     Target_Comp_ID : String;
                                     Order_ID       : String;
                                     Exec_ID        : String;
                                     Exec_Type      : String;
                                     Ord_Status     : String;
                                     Symbol         : String) return Fix_Message is
      Msg : Fix_Message := Empty_Message;
   begin
      Add_Field (Msg, 35, "8");
      Add_Field (Msg, 49, Sender_Comp_ID);
      Add_Field (Msg, 56, Target_Comp_ID);
      Add_Field (Msg, 37, Order_ID);
      Add_Field (Msg, 17, Exec_ID);
      Add_Field (Msg, 150, Exec_Type);
      Add_Field (Msg, 39, Ord_Status);
      Add_Field (Msg, 55, Symbol);
      return Msg;
   end Create_Execution_Report;

end Financial_Information_Exchange;
