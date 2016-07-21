<?php

class Counter {

    /**
     * @var PDO
     */
    protected $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
        $this->db->exec('CREATE TABLE IF NOT EXISTS `counter` (`counter` INT(20) NOT NULL);');
    }

    public function increaseCounter()
    {
        $stmt = $this->db->prepare('UPDATE counter SET counter=counter+1');
        $stmt->execute();
        if ($stmt->rowCount() == 0) {
            $this->reset();
            $this->increaseCounter();
        }
    }

    public function getCurrentCounter()
    {
        $stmt = $this->db->prepare('SELECT counter FROM counter');
        $stmt->execute();
        $result = $stmt->fetchObject();
        return $result ? $result->counter : 0;
    }

    public function reset()
    {
        $this->db->prepare('DELETE FROM counter')->execute();
        $this->db->prepare('INSERT INTO counter VALUES (0)')->execute();
    }

}