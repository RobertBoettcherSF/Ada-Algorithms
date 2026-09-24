-- ============================================================================
--  Reference Counting Package Specification
--  Implements core reference counting and all variants from Wikipedia:
--  - Basic Reference Counting
--  - Weighted Reference Counting
--  - Indirect Reference Counting (Dijkstra-Scholten)
--  - Deferred Increment (Henry Baker)
--  - Update Coalescing (Levanoni & Petrank)
--  - Cycle Handling (Bacon's algorithm, Weak References)
--  - Deutsch-Bobrow Method
--  - Ulterior Reference Counting (Blackburn & McKinley)
-- ============================================================================

with Ada.Containers.Doubly_Linked_Lists;

package Reference_Counting is

   -- ========================================================================
   --  Exceptions
   -- ========================================================================

   -- Raised when a reference count underflows (e.g., decrementing below zero)
   Reference_Count_Underflow : exception;

   -- Raised when a cycle is detected in a non-cycle-handling variant
   Cycle_Detected : exception;

   -- Raised when attempting to use an invalid (null or dangling) reference
   Invalid_Reference : exception;

   -- Raised when a weight underflows in weighted reference counting
   Weight_Underflow : exception;

   -- ========================================================================
   --  Core Types
   -- ========================================================================

   -- Reference count type (modular to prevent overflow)
   type Reference_Count is mod 2**32;

   -- Weight type for weighted reference counting (fixed-point for precision)
   type Weight is delta 0.0001 range 0.0 .. 1.0;

   -- Unique identifier for objects (to simulate memory addresses)
   type Object_ID is range 1 .. 2**31 - 1;

   -- ========================================================================
   --  Basic Reference Counting
   -- ========================================================================

   -- Forward declaration for Object type
   type Object;
   type Object_Access is access Object;

   -- Object type with reference count
   type Object is tagged limited private;

   -- Procedure to increment the reference count of an object
   procedure Increment_Reference (Obj : in out Object_Access);

   -- Procedure to decrement the reference count of an object
   -- If the count reaches zero, the object is deallocated
   procedure Decrement_Reference (Obj : in out Object_Access);

   -- Function to get the current reference count of an object
   function Get_Reference_Count (Obj : Object_Access) return Reference_Count;

   -- Function to create a new object with a reference count of 1
   function Create_Object return Object_Access;

   -- Procedure to free an object (for testing/cleanup)
   procedure Free_Object (Obj : in out Object_Access);

   -- ========================================================================
   --  Weighted Reference Counting
   -- ========================================================================

   -- Weighted object type
   type Weighted_Object;
   type Weighted_Object_Access is access Weighted_Object;

   type Weighted_Object is tagged limited private;

   -- Procedure to split a weight into two halves
   procedure Split_Weight (Obj : in out Weighted_Object_Access);

   -- Procedure to merge weights (used when a reference is destroyed)
   procedure Merge_Weight (Obj : in out Weighted_Object_Access; Amount : Weight);

   -- Function to get the total weight of a weighted object
   function Get_Total_Weight (Obj : Weighted_Object_Access) return Weight;

   -- Function to create a new weighted object with initial weight
   function Create_Weighted_Object (Initial_Weight : Weight) return Weighted_Object_Access;

   -- Procedure to free a weighted object (for testing/cleanup)
   procedure Free_Weighted_Object (Obj : in out Weighted_Object_Access);

   -- ========================================================================
   --  Indirect Reference Counting (Dijkstra-Scholten)
   -- ========================================================================

   -- Indirect reference type (for diffusion tree)
   type Indirect_Object;
   type Indirect_Object_Access is access Indirect_Object;

   type Indirect_Object is tagged limited private;

   -- Function to get the reference count of an indirect object (for testing)
   function Get_Indirect_Reference_Count (Obj : Indirect_Object_Access) return Reference_Count;

   -- Procedure to add an indirect reference
   procedure Add_Indirect_Reference (
      Source, Target : in out Indirect_Object_Access);

   -- Procedure to remove an indirect reference
   procedure Remove_Indirect_Reference (
      Source, Target : in out Indirect_Object_Access);

   -- Function to create a new indirect object
   function Create_Indirect_Object return Indirect_Object_Access;

   -- Procedure to free an indirect object (for testing/cleanup)
   procedure Free_Indirect_Object (Obj : in out Indirect_Object_Access);

   -- ========================================================================
   --  Deferred Increment (Henry Baker)
   -- ========================================================================

   -- Deferred object type (tracks whether increment is deferred)
   type Deferred_Object;
   type Deferred_Object_Access is access Deferred_Object;

   type Deferred_Object is tagged limited private;

   -- Function to get the reference count of a deferred object (for testing)
   function Get_Deferred_Reference_Count (Obj : Deferred_Object_Access) return Reference_Count;

   -- Function to check if increment is deferred (for testing)
   function Is_Deferred_Incr (Obj : Deferred_Object_Access) return Boolean;

   -- Procedure to create a local reference (deferred increment)
   procedure Create_Local_Reference (Obj : in out Deferred_Object_Access);

   -- Procedure to destroy a local reference (no decrement if deferred)
   procedure Destroy_Local_Reference (Obj : in out Deferred_Object_Access);

   -- Procedure to promote a local reference to a global one (perform deferred increment)
   procedure Promote_To_Global (Obj : in out Deferred_Object_Access);

   -- Function to create a new deferred object
   function Create_Deferred_Object return Deferred_Object_Access;

   -- Procedure to free a deferred object (for testing/cleanup)
   procedure Free_Deferred_Object (Obj : in out Deferred_Object_Access);

   -- ========================================================================
   --  Update Coalescing (Levanoni & Petrank)
   -- ========================================================================

   -- Update record type (must be defined before Update_Lists)
   type Update_Record is record
      Old_Obj : Object_Access;
      New_Obj : Object_Access;
   end record;

   -- Update coalescing manager type
   type Update_Manager;
   type Update_Manager_Access is access Update_Manager;

   type Update_Manager is tagged limited private;

   -- Function to get the number of pending updates (for testing)
   function Get_Pending_Updates_Count (Manager : Update_Manager_Access) return Natural;

   -- Procedure to register a pointer update (coalesces redundant updates)
   procedure Register_Update (
      Manager : in out Update_Manager_Access;
      Old_Obj, New_Obj : in out Object_Access);

   -- Procedure to flush all coalesced updates
   procedure Flush_Updates (Manager : in out Update_Manager_Access);

   -- Function to create a new update manager
   function Create_Update_Manager return Update_Manager_Access;

   -- Procedure to free an update manager (for testing/cleanup)
   procedure Free_Update_Manager (Manager : in out Update_Manager_Access);

   -- ========================================================================
   --  Cycle Handling (Weak References)
   -- ========================================================================

   -- Weak reference type (does not contribute to reference count)
   type Weak_Reference;
   type Weak_Reference_Access is access Weak_Reference;

   type Weak_Reference is limited private;

   -- Procedure to create a weak reference to an object
   procedure Create_Weak_Reference (
      Target : Object_Access;
      Weak_Ref : out Weak_Reference_Access);

   -- Function to check if a weak reference is still valid
   function Is_Weak_Reference_Valid (Weak_Ref : Weak_Reference_Access) return Boolean;

   -- Procedure to get the target of a weak reference (raises Invalid_Reference if invalid)
   procedure Get_Weak_Target (
      Weak_Ref : Weak_Reference_Access;
      Target : out Object_Access);

   -- Procedure to free a weak reference (for testing/cleanup)
   procedure Free_Weak_Reference (Weak_Ref : in out Weak_Reference_Access);

   -- ========================================================================
   --  Deutsch-Bobrow Method
   -- ========================================================================

   -- Deutsch-Bobrow object type (ignores local references)
   type DB_Object;
   type DB_Object_Access is access DB_Object;

   type DB_Object is tagged limited private;

   -- Function to check if the object is in the stack (for testing)
   function Is_In_Stack (Obj : DB_Object_Access) return Boolean;

   -- Function to get the reference count of a DB object (for testing)
   function Get_DB_Reference_Count (Obj : DB_Object_Access) return Reference_Count;

   -- Procedure to scan stack/registers for references (simulated)
   procedure Scan_Stack_For_References (Obj : in out DB_Object_Access);

   -- Function to create a new Deutsch-Bobrow object
   function Create_DB_Object return DB_Object_Access;

   -- Procedure to free a DB object (for testing/cleanup)
   procedure Free_DB_Object (Obj : in out DB_Object_Access);

   -- ========================================================================
   --  Ulterior Reference Counting (Blackburn & McKinley)
   -- ========================================================================

   -- Ulterior object type (combines deferred counting with copying nursery)
   type Ulterior_Object;
   type Ulterior_Object_Access is access Ulterior_Object;

   type Ulterior_Object is tagged limited private;

   -- Function to check if the object is young (for testing)
   function Is_Young (Obj : Ulterior_Object_Access) return Boolean;

   -- Function to get the reference count of an ulterior object (for testing)
   function Get_Ulterior_Reference_Count (Obj : Ulterior_Object_Access) return Reference_Count;

   -- Procedure to perform a copying collection (simulated)
   procedure Copying_Collection (Obj : in out Ulterior_Object_Access);

   -- Function to create a new ulterior object
   function Create_Ulterior_Object return Ulterior_Object_Access;

   -- Procedure to free an ulterior object (for testing/cleanup)
   procedure Free_Ulterior_Object (Obj : in out Ulterior_Object_Access);

   -- ========================================================================
   --  Cycle Detection (Bacon's Algorithm)
   -- ========================================================================

   -- Cycle detector type
   type Cycle_Detector;
   type Cycle_Detector_Access is access Cycle_Detector;

   type Cycle_Detector is tagged limited private;

   -- Function to get the number of roots (for testing)
   function Get_Roots_Count (Detector : Cycle_Detector_Access) return Natural;

   -- Procedure to add an object to the roots list (for cycle detection)
   procedure Add_To_Roots (Detector : in out Cycle_Detector_Access; Obj : Object_Access);

   -- Procedure to detect and collect cycles
   procedure Detect_Cycles (Detector : in out Cycle_Detector_Access);

   -- Function to create a new cycle detector
   function Create_Cycle_Detector return Cycle_Detector_Access;

   -- Procedure to free a cycle detector (for testing/cleanup)
   procedure Free_Cycle_Detector (Detector : in out Cycle_Detector_Access);

private

   -- ========================================================================
   --  Basic Object Implementation
   -- ========================================================================

   type Object is tagged limited record
      ID          : Object_ID;
      Ref_Count   : Reference_Count;
   end record;

   -- ========================================================================
   --  Weighted Object Implementation
   -- ========================================================================

   type Weighted_Object is tagged limited record
      ID           : Object_ID;
      Total_Weight : Weight;
   end record;

   -- ========================================================================
   --  Indirect Object Implementation (Dijkstra-Scholten)
   -- ========================================================================

   type Indirect_Object is tagged limited record
      ID               : Object_ID;
      Ref_Count        : Reference_Count;
   end record;

   -- ========================================================================
   --  Deferred Object Implementation
   -- ========================================================================

   type Deferred_Object is tagged limited record
      ID               : Object_ID;
      Ref_Count        : Reference_Count;
      Deferred_Incr    : Boolean := False; -- Whether increment is deferred
   end record;

   -- ========================================================================
   --  Update Manager Implementation
   -- ========================================================================

   -- Instantiate the generic list for Update_Record
   package Update_Lists is new Ada.Containers.Doubly_Linked_Lists(Update_Record);

   type Update_Manager is tagged limited record
      Pending_Updates : Update_Lists.List;
   end record;

   -- ========================================================================
   --  Weak Reference Implementation
   -- ========================================================================

   type Weak_Reference is limited record
      Target_ID : Object_ID;
      Is_Valid  : Boolean := True;
   end record;

   -- ========================================================================
   --  Deutsch-Bobrow Object Implementation
   -- ========================================================================

   type DB_Object is tagged limited record
      ID          : Object_ID;
      Ref_Count   : Reference_Count;
      In_Stack    : Boolean := False; -- Simulates whether it's in stack/registers
   end record;

   -- ========================================================================
   --  Ulterior Object Implementation
   -- ========================================================================

   type Ulterior_Object is tagged limited record
      ID          : Object_ID;
      Ref_Count   : Reference_Count;
      Is_Young    : Boolean := True; -- Simulates nursery status
   end record;

   -- ========================================================================
   --  Cycle Detector Implementation
   -- ========================================================================

   -- Instantiate the generic list for Object_Access
   package Object_Lists is new Ada.Containers.Doubly_Linked_Lists(Object_Access);

   type Cycle_Detector is tagged limited record
      Roots       : Object_Lists.List;
   end record;

end Reference_Counting;
