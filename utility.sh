#!/bin/bash

# Функция для вывода справки
function show_help {
    echo "Usage: utility.sh [OPTIONS]"
    echo "Options:"
    echo "  -u, --users     Display a list of users and their home directories, sorted alphabetically."
    echo "  -p, --processes Display a list of running processes, sorted by their ID."
    echo "  -h, --help      Show this help message and exit."
    echo "  -l PATH         Redirect the output to a file at the given PATH."
    echo "  --log PATH      Redirect the output to a file at the given PATH."
    echo "  -e PATH         Redirect the error output to a file at the given PATH."
    echo "  --errors PATH   Redirect the error output to a file at the given PATH."
}

# Функция для вывода списка пользователей и их домашних директорий
function display_users {
    # Получаем список пользователей и их домашних директорий
    users=$(cut -d: -f1,6 /etc/passwd | sort)

    # Проверяем, нужно ли перенаправить вывод в файл
    if [ -n "$output_file" ]; then
        echo "$users" > "$output_file"
    else
        echo "$users"
    fi
}

# Функция для вывода списка запущенных процессов
function display_processes {
    # Получаем список запущенных процессов, сортируем по их идентификатору (PID)
    processes=$(ps -e -o pid,cmd --sort=pid)

    # Проверяем, нужно ли перенаправить вывод в файл
    if [ -n "$output_file" ]; then
        echo "$processes" > "$output_file"
    else
        echo "$processes"
    fi
}

function redirect_output {
    echo "Redirecting output to $output_file"
    if [ -z "$output_file" ]; then
        echo "Error: Path to output file is not specified."
        exit 1
    fi

    if ! touch "$output_file" 2> /dev/null; then
        echo "Error: Cannot access the specified path for output file."
        exit 1
    fi

    exec > "$output_file"
    echo "Output redirection successful"
}

function redirect_errors {
    echo "Redirecting errors to $error_file"
    if [ -z "$error_file" ]; then
        echo "Error: Path to error file is not specified."
        exit 1
    fi

    if ! touch "$error_file" 2> /dev/null; then
        echo "Error: Cannot access the specified path for error file."
        exit 1
    fi

    exec 2> "$error_file"
    echo "Error redirection successful"
}

# Обработка аргументов командной строки
while getopts ":u:p:hl:e:-:" opt; do
    case "$opt" in
        u)
            display_users
            ;;
        p)
            display_processes
            ;;
        h)
            show_help
            exit 0
            ;;
        l)
            output_file=$OPTARG
            redirect_output
            ;;
        e)
            error_file=$OPTARG
            redirect_errors
            ;;
        -)
            case "${OPTARG}" in
                users)
                    display_users
                    ;;
                processes)
                    display_processes
                    ;;
                help)
                    show_help
                    exit 0
                    ;;
                log)
                    output_file=${!OPTIND}
                    OPTIND=$((OPTIND + 1))
                    redirect_output
                    ;;
                errors)
                    error_file=${!OPTIND}
                    OPTIND=$((OPTIND + 1))
                    redirect_errors
                    ;;
                *)
                    echo "Error: Invalid option --$OPTARG"
                    exit 1
                    ;;
            esac
            ;;
        :)
            echo "Error: Option -$OPTARG requires an argument."
            exit 1
            ;;
        ?)
            echo "Error: Invalid option -$OPTARG"
            exit 1
            ;;
    esac
done

# Если не передано ни одного аргумента, выводим справку
if [[ $# -eq 0 ]]; then
    show_help
fi
