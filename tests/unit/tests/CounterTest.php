<?php

require __DIR__ . '/../../../nano-app/Counter.php';

class CounterTest extends PHPUnit_Framework_TestCase
{

    /**
     * @var Counter
     */
    protected $counter;

    public function setUp()
    {
        $this->counter = new Counter(new PDO('sqlite::memory:'));
    }

    public function testIncreaseCount()
    {
        $counterBefore = $this->counter->getCurrentCounter();
        $this->counter->increaseCounter();
        $counterAfter = $this->counter->getCurrentCounter();
        $this->assertGreaterThan($counterBefore, $counterAfter);
    }

    public function testCounterDoesNotChangeIfNotIncreased()
    {
        $this->counter->increaseCounter();
        $counterFirst = $this->counter->getCurrentCounter();
        $counterThen = $this->counter->getCurrentCounter();
        $this->assertEquals($counterFirst, $counterThen);
    }

    public function testZeroAfterResetting()
    {
        $this->counter->increaseCounter();
        $counterFirst = $this->counter->getCurrentCounter();
        $this->assertGreaterThan(0, $counterFirst);
        $this->counter->reset();
        $counterThen = $this->counter->getCurrentCounter();
        $this->assertEquals(0, $counterThen);
    }

}