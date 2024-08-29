#!/bin/bash

# ANSI Colors for terminal output formatting
RED='\033[0;31m' # Red color
NC='\033[0m' # No Color (reset color)

# File paths for storing data
student_file="students.csv"
teacher_file="teachers.csv"
course_file="courses.csv"
course_students_file="course_students.csv"
course_teacher_file="course_teacher.csv"
attendance_file="attendance.csv"

# Initialize files with headers if they do not exist
[[ ! -f $student_file ]] && echo "ID,Name,Age" > $student_file
[[ ! -f $teacher_file ]] && echo "ID,Name,Subject" > $teacher_file
[[ ! -f $course_file ]] && echo "CourseName,CourseCode,TeacherID" > $course_file
[[ ! -f $course_students_file ]] && echo "CourseCode,StudentID" > $course_students_file
[[ ! -f $course_teacher_file ]] && echo "CourseCode,TeacherID" > $course_teacher_file
[[ ! -f $attendance_file ]] && echo "ID,Date,Status" > $attendance_file

# Function to create a new course
create_course() {
    echo -e "${RED}Enter course name:${NC}" # Prompt for course name
    read course_name # Read course name input
    echo -e "${RED}Enter course code:${NC}" # Prompt for course code
    read course_code # Read course code input
    echo -e "${RED}Enter the start date of the course (e.g., YYYY-MM-DD) ${NC}:" # Prompt for course start date
    read class_date # Read start date input
    echo -e "${RED}Enter the time of the class (e.g., HH:MM):${NC}" # Prompt for class time
    read class_time # Read class time input
    echo "$course_name,$course_code,$class_date,$class_time" >> $course_file # Append course details to file
    echo "Course '$course_name' with code '$course_code' successfully created." # Confirmation message
}

# Function to add a new student
add_student() {
    echo -e "${RED}Enter student name:${NC}" # Prompt for student name
    read name # Read student name input
    echo -e "${RED}Enter student ID:${NC}" # Prompt for student ID
    read id # Read student ID input
    echo -e "${RED}Enter student age:${NC}" # Prompt for student age
    read age # Read student age input
    echo "$id,$name,$age" >> $student_file # Append student details to file
    echo "Student $name added successfully." # Confirmation message
}

# Function to assign a student to one or more courses
assign_student_to_course() {
    echo -e "${RED}Enter student ID:${NC}" # Prompt for student ID
    read student_id # Read student ID input
    echo -e "${RED}Enter course codes to assign (separate by commas if multiple):${NC}" # Prompt for course codes
    read input_courses # Read course codes input
    IFS=',' read -r -a course_codes <<< "$input_courses" # Split input into an array of course codes

    # Check if the student exists in the student file
    if ! grep -q "^$student_id," "$student_file"; then
        echo "No student found with ID $student_id." # Error message if student not found
        return # Exit function
    else
        echo "Student ID $student_id found." # Confirmation message if student found
    fi

    for course_code in "${course_codes[@]}"; do # Loop through each course code
        course_code=$(echo "$course_code" | xargs)  # Trim whitespace from course code

        # Check if the course exists in the course file
        if ! grep -q "^$course_code," "$course_file"; then
            echo "Course code $course_code does not exist." # Error message if course not found
            continue # Skip to the next course code
        else
            echo "Course code $course_code exists." # Confirmation message if course found
        fi

        # Check if the student is already assigned to the course
        if grep -q "$course_code,$student_id" "$course_students_file"; then
            echo "Student $student_id is already assigned to $course_code." # Message if already assigned
        else
            echo "$course_code,$student_id" >> "$course_students_file" # Assign student to course
            echo "Student $student_id assigned to $course_code successfully." # Confirmation message
        fi
    done
}

# Function to update student information
update_student() {
    echo -e "${RED}Enter the student ID to update:${NC}" # Prompt for student ID to update
    read student_id # Read student ID input
    local existing_entry=$(grep "^$student_id," $student_file) # Find existing student entry
    if [[ -n "$existing_entry" ]]; then # Check if entry exists
        echo "Student found: $existing_entry" # Show existing student entry
        echo "What would you like to update?" # Prompt for update choice
        echo "1. Name" # Option to update name
        echo "2. Age" # Option to update age
        echo "3. Courses" # Option to update courses
        read update_choice # Read update choice input
        case "$update_choice" in
            1)
                echo -e "${RED}Enter new name for the student:${NC}" # Prompt for new name
                read new_name # Read new name input
                local age=$(echo "$existing_entry" | cut -d ',' -f 3) # Extract age from entry
                sed -i '' "s|^$student_id,.*|$student_id,$new_name,$age|" $student_file # Update name in file
                echo "Student name updated successfully." # Confirmation message
                ;;
            2)
                echo -e "${RED}Enter new age for the student:${NC}" # Prompt for new age
                read new_age # Read new age input
                local name=$(echo "$existing_entry" | cut -d ',' -f 2) # Extract name from entry
                sed -i '' "s|^$student_id,.*|$student_id,$name,$new_age|" $student_file # Update age in file
                echo "Student age updated successfully." # Confirmation message
                ;;
            3)
                echo "Do you want to:" # Prompt for course action
                echo -e "1. Add a course" # Option to add course
                echo -e "2. Remove a course" # Option to remove course
                echo -e "${RED} Choose Your Option: ${NC}" # Prompt for choice
                read course_action # Read choice input
                case "$course_action" in
                    1)
                        echo -e "${RED}Enter course name to add:${NC}" # Prompt for course to add
                        read course_name # Read course name input
                        if ! grep -q "^$course_name," "$course_file" ; then # Check if course exists
                            echo "No Such Course $course_name exists" # Error message if course not found
                            return # Exit function
                        fi
                        if grep -q "$course_name,$student_id" $course_students_file; then # Check if already enrolled
                            echo "Student already enrolled in $course_name." # Message if already enrolled
                        else
                            echo "$course_name,$student_id" >> $course_students_file # Enroll student in course
                            echo "Student enrolled in $course_name successfully." # Confirmation message
                        fi
                        ;;
                    2)
                        echo -e "${RED}Enter course code to remove:${NC}" # Prompt for course to remove
                        read course_code # Read course code input
                        if ! grep -q "^$course_name," "$course_file" ; then # Check if course exists
                            echo "No Such Course $course_name exists" # Error message if course not found
                            return # Exit function
                        fi
                        if grep -q "$course_code,$student_id" $course_students_file; then # Check if enrolled
                            grep -v "$course_code,$student_id" $course_students_file > temp_file.csv # Remove enrollment
                            mv temp_file.csv $course_students_file # Update file
                            echo "Student removed from $course_code successfully." # Confirmation message
                        else
                            echo "Student not enrolled in $course_name." # Message if not enrolled
                        fi
                        ;;
                    *)
                        echo "Invalid action selected. Please choose 1 or 2." # Error message for invalid choice
                        ;;
                esac
                ;;
            *)
                echo "Invalid update choice. Please enter 1, 2, or 3." # Error message for invalid update choice
                ;;
        esac
    else
        echo "No student found with ID $student_id." # Error message if student not found
    fi
}

# Function to add a new teacher
add_teacher() {
    echo -e "${RED}Enter teacher name:${NC}" # Prompt for teacher name
    read name # Read teacher name input
    echo -e "${RED}Enter teacher ID:${NC}" # Prompt for teacher ID
    read id # Read teacher ID input
    echo "$id,$name" >> $teacher_file # Append teacher details to file
    echo "Teacher $name added successfully." # Confirmation message
}

# Function to assign a teacher to one or more courses
assign_teacher_to_course() {
    echo -e "${RED}Enter teacher ID:${NC}" # Prompt for teacher ID
    read teacher_id # Read teacher ID input
    echo -e "${RED}Enter course codes to assign (separate by commas if multiple):${NC}" # Prompt for course codes
    read input_courses # Read course codes input
    IFS=',' read -r -a course_codes <<< "$input_courses" # Split input into an array of course codes

    # Check if the teacher exists
    if ! grep -q "^$teacher_id," "$teacher_file"; then # Check if teacher exists in file
        echo "No teacher found with ID $teacher_id." # Error message if teacher not found
        return # Exit function
    fi

    for course_code in "${course_codes[@]}"; do # Loop through each course code
        course_code=$(echo "$course_code" | xargs)  # Trim whitespace from course code
        # Check if the course exists
        if ! grep -q "^$course_code," "$course_file"; then # Check if course exists in file
            echo "Course code $course_code does not exist." # Error message if course not found
            continue # Skip to the next course code
        fi
        # Check if the teacher is already assigned to the course
        if grep -q "$course_code,$teacher_id" "$course_teacher_file"; then # Check if already assigned
            echo "Teacher $teacher_id is already assigned to course code $course_code." # Message if already assigned
        else
            echo "$course_code,$teacher_id" >> "$course_teacher_file" # Assign teacher to course
            echo "Teacher $teacher_id assigned to course code $course_code successfully." # Confirmation message
        fi
    done
}

# Function to update teacher information
update_teacher() {
    echo -e "${RED}Enter teacher ID: ${NC}" # Prompt for teacher ID to update
    read id # Read teacher ID input
    local existing_entry=$(grep "^$id," $teacher_file) # Find existing teacher entry
    if [[ -n "$existing_entry" ]]; then # Check if entry exists
        echo "Teacher found: $existing_entry" # Show existing teacher entry
        echo "What would you like to update?" # Prompt for update choice
        echo "1. Name" # Option to update name
        echo "2. Courses" # Option to update courses
        echo -e "${RED}Enter Your Choice:${NC}" # Prompt for choice
        read update_choice # Read choice input

        case "$update_choice" in
            1)
                echo -e "${RED}Enter new name for the teacher:${NC}" # Prompt for new name
                read new_name # Read new name input
                local courses=$(echo "$existing_entry" | cut -d ',' -f 3) # Extract courses from entry
                sed -i "s|^$id,.*|$id,$new_name,$courses|" $teacher_file # Update name in file
                echo "Teacher name updated successfully." # Confirmation message
                ;;
            2)
                echo "Do you want to:" # Prompt for course action
                echo "1. Add a course" # Option to add course
                echo "2. Remove a course" # Option to remove course
                echo -e "${RED}Enter Your Choice: ${NC}" # Prompt for choice
                read course_action # Read choice input
                local courses=$(echo "$existing_entry" | cut -d ',' -f 3) # Extract courses from entry
                case "$course_action" in
                    1)
                        echo -e "${RED}Enter course name to add:${NC}" # Prompt for course to add
                        read course_name # Read course name input
                        if ! grep -q "^$course_name," $course_file; then # Check if course exists
                            echo "Course name $course_name does not exist." # Error message if course not found
                        elif [[ ";$courses;" == *";$course_name;"* ]]; then # Check if already assigned
                            echo "Course '$course_name' already assigned to teacher ID $id." # Message if already assigned
                        else
                            courses="${courses};$course_name" # Add course to teacher
                            sed -i "s|^$id,.*|$id,$new_name,$courses|" $teacher_file # Update file
                            echo "Course '$course_name' added successfully." # Confirmation message
                        fi
                        ;;
                    2)
                        echo -e "${RED}Enter course name to remove:${NC}" # Prompt for course to remove
                        read course_name # Read course name input
                        IFS=';' read -r -a courses_array <<< "$courses" # Split courses into array
                        new_courses="" # Initialize new courses variable
                        for current_course in "${courses_array[@]}"; do # Loop through courses
                            if [[ "$current_course" != "$course_code" ]]; then # Check if course matches
                                if [[ -z "$new_courses" ]]; then # Check if new_courses is empty
                                    new_courses="$current_course" # Add course to new_courses
                                else
                                    new_courses="$new_courses;$current_course" # Append course to new_courses
                                fi
                            fi
                        done
                        if [[ "$new_courses" == "$courses" ]]; then # Check if any course was removed
                            echo "Course '$course_name' not found for teacher ID $id." # Message if not found
                        else
                            sed -i "s|^$id,.*|$id,$new_name,$new_courses|" $teacher_file # Update file
                            echo "Course '$course_name' removed successfully." # Confirmation message
                        fi
                        ;;
                    *)
                        echo "Invalid action selected. Please choose 1 or 2." # Error message for invalid choice
                        ;;
                esac
                ;;
            *)
                echo "Invalid update choice. Please enter 1 or 2." # Error message for invalid update choice
                ;;
        esac
    else
        echo "No teacher found with ID $id. Adding new teacher." # Message if teacher not found
        echo "Enter teacher name:" # Prompt for teacher name
        read name # Read teacher name input
        echo "Enter course code:" # Prompt for course code
        read course_name # Read course code input
        if ! grep -q "^$course_name," $course_file; then # Check if course exists
            echo "Course name $course_name does not exist. Cannot add new teacher." # Error message if course not found
        else
            echo "$id,$name,$course_name" >> $teacher_file # Add new teacher
            echo "New teacher $name with ID $id and course $course_name added." # Confirmation message
        fi
    fi
}

# Function to record attendance for a student
record_attendance() {
    echo -e "${RED}Enter ID student:${NC}" # Prompt for student ID
    read id # Read student ID input
    echo -e "${RED}Enter date (YYYY-MM-DD):${NC}" # Prompt for date
    read date # Read date input

    echo -e "${RED}Enter status (P for Present, A for Absent, L for Late):${NC}" # Prompt for status
    echo "P. Present" # Present option
    echo "A. Absent" # Absent option
    echo "L. Late" # Late option
    echo -e "${RED}Enter the Status here: ${NC}" # Prompt for choice
    read status # Read status input

    case $status in # Convert status input to full word
        [pP])
            status="Present"
            ;;
        [aA])
            status="Absent"
            ;;
        [lL])
            status="Late"
            ;;
    esac
    echo "$id,$date,$status" >> $attendance_file # Record attendance in file
    echo "Attendance for $id on $date recorded as $status." # Confirmation message
}

# Function to search for a course by name or code
search_course() {
    echo -e "${RED}Enter course name or course code to search:${NC}" # Prompt for search term
    read search_term # Read search term input
    echo "Search results for course:" # Message for search results
    grep -i "$search_term" $course_file | while IFS=',' read -r course_name course_code start_date class_time # Search courses
    do
        teacher_id=$(grep "^$course_code," $course_teacher_file | cut -d ',' -f 2) # Find teacher ID for course
        teacher_name="Not assigned" # Default teacher name
        if [[ -n "$teacher_id" ]]; then # Check if teacher assigned
            teacher_name=$(grep "^$teacher_id," $teacher_file | cut -d ',' -f 2) # Find teacher name
        fi
        echo "$course_name | $course_code | $start_date | $class_time | Teacher: $teacher_name" # Display course details
    done
}

# Function to search for a student by ID or name
search_student() {
    echo -e "${RED}Enter student ID or name to search:${NC}" # Prompt for search term
    read search_term # Read search term input
    echo "Search results for student:" # Message for search results
    awk -F, -v term="$search_term" 'BEGIN {IGNORECASE=1} # Search students using awk
        $1 == term || $2 ~ term {print "ID: " $1 ", Name: " $2 ", Age: " $3}' $student_file
}

# Function to search for a teacher by ID or name
search_teacher() {
    echo -e "${RED}Enter teacher ID or name to search:${NC}" # Prompt for search term
    read search_term # Read search term input
    echo "Search results for teacher:" # Message for search results
    grep -i "$search_term" $teacher_file  | while IFS=',' read id name; do # Search teachers
        echo "ID: $id, Name: $name" # Display teacher details
    done
}

# Function to list all courses with details
list_all_courses() {
    echo -e "${RED}All Courses and Their Details:${NC}" # Message for course list
    echo "Course Name | Course Code | Class Time | Assigned Teacher" # Column headers

    while IFS=',' read -r course_name course_code class_date class_time # Read each course
    do
        teacher_name="Not Assigned" # Default teacher name

        teacher_id=$(awk -F, -v name="$course_name" '$1 == name {print $2}' $course_teacher_file) # Find teacher ID

        if [[ -n "$teacher_id" ]]; then # Check if teacher assigned
            teacher_name=$(awk -F, -v id="$teacher_id" '$1 == id {print $2}' $teacher_file) # Find teacher name
        fi

        class_time_formatted="${class_time}" # Format class time

        echo "${course_name} | ${course_code} | ${class_time_formatted} | ${teacher_name}" # Display course details
    done < $course_file
}

# Function to list all students with their courses
list_all_students() {
    echo -e "${RED}All Students And Their Courses:${NC}" # Message for student list
    echo "ID,Name,Age,Enrolled Courses" # Column headers
    while IFS=',' read -r id name age; do # Read each student
        course_name=$(awk -F, -v id="$id" '$2 == id {printf "%s;", $1}' $course_students_file | sed 's/;$//') # Find courses for student
        echo "$id,$name,$age,$course_name" # Display student details
    done < $student_file | column -t -s ',' # Format output
}

# Function to list all teachers with their courses
list_all_teachers() {
    echo "All Teachers And Their Courses:" # Message for teacher list
    while IFS=',' read -r id name; do # Read each teacher
        course_name=$(awk -F, -v id="$id" '$2 == id {printf "%s;", $1}' $course_teacher_file | sed 's/;$//') # Find courses for teacher
        echo "$id, $name, $course_name" # Display teacher details
    done < $teacher_file | column -t -s ',' # Format output
}

# Main menu function to navigate options
main_menu() {
    while true; do # Infinite loop for menu
        echo "Choose an option:" # Prompt for menu option
        echo "1) Create Course" # Option to create course
        echo "2) Add Student" # Option to add student
        echo "3) Assign Student to Course" # Option to assign student to course
        echo "4) Update Student" # Option to update student
        echo "5) Add Teacher" # Option to add teacher
        echo "6) Assign Teacher to Course" # Option to assign teacher to course
        echo "7) Update Teacher" # Option to update teacher
        echo "8) Search Course" # Option to search course
        echo "9) Search Student" # Option to search student
        echo "10) Search Teacher" # Option to search teacher
        echo "11) Record Attendance" # Option to record attendance
        echo "12) List All Courses" # Option to list all courses
        echo "13) List All Students and their Courses " # Option to list all students
        echo "14) List All Teachers and their Courses" # Option to list all teachers
        echo "15) Exit" # Option to exit menu
        echo -n -e "${RED}Enter your choice:${NC} " # Prompt for choice
        read option # Read choice input
        case "$option" in # Execute corresponding function
            1) create_course ;;
            2) add_student ;;
            3) assign_student_to_course ;;
            4) update_student ;;
            5) add_teacher ;;
            6) assign_teacher_to_course ;;
            7) update_teacher ;;
            8) search_course ;;
            9) search_student ;;
            10) search_teacher ;;
            11) record_attendance ;;
            12) list_all_courses ;;
            13) list_all_students ;;
            14) list_all_teachers ;;
            15) break ;; # Exit loop
            *) echo "Invalid option. Please try again." ;; # Error message for invalid choice
        esac
    done
}

main_menu # Call the main menu function