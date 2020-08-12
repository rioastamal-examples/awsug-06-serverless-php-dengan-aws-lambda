<?php

$dsn = $_POST['dsn'] ?? '';
$username = $_POST['username'] ?? 'root';
$password = $_POST['password'] ?? '';
$query = $_POST['query'] ?? '';
$pdo = null;

function exec_query($pdo, $query)
{
    if (empty($query)) {
        return '// Result will be shown here';
    }

    $counter = 0;

    try {
        echo '<table>';
        foreach ($pdo->query($query, PDO::FETCH_ASSOC) as $row) {
            // --- HEADING --- //
            if ($counter === 0) {
                echo '<thead><tr>';

                foreach ($row as $key => $val) {
                    printf('<td>%s</td>', $key);
                }

                echo '</tr></thead><tbody>';
            }
            // --- /HEADING --- //

            echo '<tr>';
            foreach ($row as $val) {
                printf('<td>%s</td>', $val);
            }
            echo '</tr>';

            $counter++;
        }

        echo '</tbody></table>';
    } catch (PDOException $e) {
        printf('<pre>Error: %s</pre>', $e->getMessage());
    }
}

if ($dsn) {
    try {
        $pdo = new PDO($dsn, $username, $password);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    } catch (PDOException $e) {
        echo 'Connection failed: ' . $e->getMessage();
    }
}

?><!DOCTYPE html>
<html lang="en">
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>Query Browser on AWS Lambda</title>
    <style type="text/css">
        label {
            display: block;
        }
        div.label-wrapper {
            width: 300px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
        }
        thead td {
            background-color: #f1f1f1;
            font-weight: bold;
        }
        tr td {
            border: 1px solid #ccc;
            padding: 4px 8px;
        }
    </style>
</head>
<body>
    <h2>Query Browser on AWS Lambda</h2>
    <form method="post">
        <label>MySQL DSN</label>
        <input type="text" name="dsn" placeholder="mysql:dbname=testdb;host=127.0.0.1" style="width: 300px;" value="<?= $dsn ?>">
        <label>Username / Password</label>
        <input type="text" name="username" placeholder="MySQL Username" value="<?= $username; ?>">
        <input type="password" name="password" placeholder="MySQL Password" value="<?= $password; ?>">

        <br><br>
        <label>SQL Query</label>
        <textarea style="width: 99%;height: 200px; font-size: 24px; color: blue;" name="query"><?= htmlentities($query) ?></textarea>
        <input type="submit" value="RUN">
    </form>

    <hr>
    <?php exec_query($pdo, $query) ?>
</body>
</html>
