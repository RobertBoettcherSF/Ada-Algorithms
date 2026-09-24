with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

--  Financial Information eXchange (FIX) Protocol Implementation
--  This package provides a strongly-typed framework for creating,
--  parsing, and serializing FIX messages according to the standard.
package Financial_Information_Exchange is

   --  Strongly typed custom domains
   type Tag_Number is new Positive;
   subtype Checksum_Value is Natural range 0 .. 255;

   --  Constants
   SOH : constant Character := Character'Val (1);

   --  Core Message Type
   type Fix_Message is private;

   --  Exceptions
   Malformed_Message : exception;
   Field_Not_Found   : exception;
   Invalid_Checksum  : exception;
   Capacity_Exceeded : exception;

   --  Message Construction & Operations
   function Empty_Message return Fix_Message
     with Global => null;

   procedure Add_Field (Msg   : in out Fix_Message;
                        Tag   : Tag_Number;
                        Value : String)
     with Pre    => Value'Length > 0,
          Global => null;

   function Has_Field (Msg : Fix_Message; Tag : Tag_Number) return Boolean
     with Global => null;

   function Get_Field (Msg : Fix_Message; Tag : Tag_Number) return String
     with Pre    => Has_Field (Msg, Tag),
          Global => null;

   --  Algorithms / Actions
   function Calculate_Checksum (Raw_Message : String) return Checksum_Value
     with Global => null;

   function Calculate_Body_Length (Msg : Fix_Message) return Natural
     with Global => null;

   --  Serialization / Parsing
   function Serialize (Msg : Fix_Message) return String
     with Global => null,
          Post   => Serialize'Result'Length > 0;

   function Parse (Raw_Message : String; Validate_Checksum : Boolean := True) return Fix_Message
     with Pre    => Raw_Message'Length > 0,
          Global => null;

   --  Message Variants (Protocol-specific constructors)
   
   --  Variant 1: Heartbeat (MsgType=0)
   function Create_Heartbeat (Sender_Comp_ID : String;
                              Target_Comp_ID : String) return Fix_Message
     with Global => null;

   --  Variant 2: New Order Single (MsgType=D)
   function Create_New_Order_Single (Sender_Comp_ID : String;
                                     Target_Comp_ID : String;
                                     Symbol         : String;
                                     Side           : String;
                                     Order_Qty      : Positive;
                                     Price          : Float) return Fix_Message
     with Global => null;

   --  Variant 3: Execution Report (MsgType=8)
   function Create_Execution_Report (Sender_Comp_ID : String;
                                     Target_Comp_ID : String;
                                     Order_ID       : String;
                                     Exec_ID        : String;
                                     Exec_Type      : String;
                                     Ord_Status     : String;
                                     Symbol         : String) return Fix_Message
     with Global => null;

private

   Max_Fields : constant := 128;
   
   type Field_Record is record
      Tag   : Tag_Number;
      Value : Unbounded_String;
   end record;

   type Field_Array is array (1 .. Max_Fields) of Field_Record;

   type Fix_Message is record
      Count  : Natural := 0;
      Fields : Field_Array;
   end record;

end Financial_Information_Exchange;
